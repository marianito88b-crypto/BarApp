import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Mixin que proporciona la lógica de negocio para la gestión de reservas.
/// 
/// Este mixin maneja:
/// - Monitor de tiempo real para alertas y auto-ocupación
/// - Limpieza automática de reservas vencidas
/// - Sistema de audio para alertas
/// - Actualización de estados de reservas y mesas
/// 
/// IMPORTANTE: Debe llamarse a `disposeReservasLogic()` en el dispose del State
/// para evitar fugas de memoria.
mixin ReservasLogicMixin<T extends StatefulWidget> on State<T> {
  // 🔊 Variables para Audio y Monitor
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool alertasSonorasActivas = true;
  Timer? _monitorTimer;
  final Set<String> _alertedReservations = {};
  DateTime? _ultimaLimpiezaReservas;
  final Duration _intervaloLimpieza = const Duration(minutes: 30);

  /// Obtiene el placeId del widget.
  /// 
  /// Debe ser implementado por la clase que usa el mixin
  /// para proporcionar el ID del lugar.
  String get placeId;

  /// Callback opcional para cambiar el filtro cuando se presiona "VER" en la alerta.
  /// 
  /// Si se proporciona, se llamará cuando el usuario presione el botón "VER"
  /// en la alerta de reserva próxima.
  void Function(String)? onFiltroChanged;

  /// Inicializa el monitor de reservas.
  /// 
  /// Debe ser llamado en initState() después de super.initState().
  /// Realiza una limpieza inicial y luego inicia el monitor periódico.
  void initReservasLogic() {
    // 1. Limpieza inicial (El "Barrido")
    limpiarReservasVencidas();

    // 2. Iniciamos el monitor en tiempo real
    startReservationMonitor();
  }

  /// Limpia todos los recursos del Mixin.
  /// 
  /// CRÍTICO: Debe ser llamado en dispose() antes de super.dispose()
  /// para evitar fugas de memoria.
  void disposeReservasLogic() {
    _monitorTimer?.cancel(); // 🛑 Detener timer
    _audioPlayer.dispose(); // 🛑 Liberar recursos de audio
  }

  // ===========================================================================
  // 🧹 LÓGICA DE LIMPIEZA (EL RELOJ SUIZO)
  // ===========================================================================
  /// Limpia reservas vencidas marcándolas como 'no_asistio'.
  /// 
  /// Busca reservas pendientes que tengan más de 3 horas de antigüedad
  /// y las marca como ausentes para métricas futuras.
  Future<void> limpiarReservasVencidas() async {
    try {
      final now = DateTime.now();
      final limiteTolerancia = now.subtract(const Duration(hours: 3));

      final query = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('reservas')
          .where('estado', isEqualTo: 'pendiente')
          .where('fecha', isLessThan: Timestamp.fromDate(limiteTolerancia))
          .get();

      if (query.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in query.docs) {
        // Marcamos como ausente para métricas futuras
        batch.update(doc.reference, {'estado': 'no_asistio'});
      }

      await batch.commit();
      debugPrint(
        "🧹 Se limpiaron ${query.docs.length} reservas vencidas (Zombis).",
      );
    } catch (e) {
      // Nota: Si falla aquí es probable que falte el Índice Compuesto en Firebase.
      // Firebase te tirará un link en la consola, dale click para crearlo.
      debugPrint("Error limpiando reservas (Check Indexes): $e");
    }
  }

  // ===========================================================================
  // 🔥 LÓGICA DEL MONITOR (Alertas + Auto-Ocupar)
  // ===========================================================================
  /// Inicia el monitor de reservas en tiempo real.
  /// 
  /// Realiza un check inmediato y luego ejecuta checks periódicos cada 60 segundos.
  /// También ejecuta limpieza periódica cada 30 minutos.
  void startReservationMonitor() {
    _monitorTimer?.cancel(); // Limpieza preventiva

    // Check inmediato al arrancar
    checkReservationsLogic();

    _monitorTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      await checkReservationsLogic();

      // Limpieza periódica cada 30 min
      final now = DateTime.now();
      if (_ultimaLimpiezaReservas == null ||
          now.difference(_ultimaLimpiezaReservas!) >= _intervaloLimpieza) {
        _ultimaLimpiezaReservas = now;
        await limpiarReservasVencidas();
      }
    });
  }

  /// Verifica las reservas confirmadas y ejecuta alertas o auto-ocupación.
  /// 
  /// Solo procesa reservas del día actual para optimizar rendimiento.
  /// - Si la reserva ya pasó (dentro de 2 horas), auto-ocupa la mesa
  /// - Si faltan 15 minutos o menos, dispara una alerta
  Future<void> checkReservationsLogic() async {
    if (!mounted) return;

    final now = DateTime.now();
    // Definimos una ventana de tiempo corta para el monitor para no leer de más
    final inicioHoy = DateTime(now.year, now.month, now.day);
    final finHoy = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("places")
          .doc(placeId)
          .collection("reservas")
          .where('estado', isEqualTo: 'confirmada')
          // IMPORTANTE: Solo traemos las de hoy para el monitor
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finHoy))
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final DateTime fechaReserva = (data['fecha'] as Timestamp).toDate();

        // Calculamos la diferencia
        final diffMinutes = fechaReserva.difference(now).inMinutes;

        // CASO 1: YA ES LA HORA O PASÓ (Tolerancia de 1 min) -> AUTO OCUPAR
        if (diffMinutes <= 0) {
          // Solo intentamos auto-ocupar si no pasó demasiado tiempo (ej. 2 horas)
          if (diffMinutes > -120) {
            await autoOcuparMesa(doc.id, data);
          }
        }
        // CASO 2: ALERTA 15 MIN
        else if (diffMinutes <= 15 && diffMinutes > 0) {
          final alertaYaEnviada = data['alerta15minEnviada'] == true;

          if (!alertaYaEnviada && !_alertedReservations.contains(doc.id)) {
            triggerAlert(data['cliente'] ?? 'Cliente', diffMinutes);
            _alertedReservations.add(doc.id);

            // Persistimos para que otros dispositivos sepan que ya sonó
            doc.reference.update({"alerta15minEnviada": true});
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error monitor reservas: $e");
    }
  }

  // ===========================================================================
  // 🔊 SISTEMA DE AUDIO Y ALERTAS
  // ===========================================================================
  /// Dispara una alerta visual y sonora cuando una reserva está próxima.
  /// 
  /// Parámetros:
  /// - [cliente]: Nombre del cliente que tiene la reserva
  /// - [minutos]: Minutos restantes hasta la reserva
  void triggerAlert(String cliente, int minutos) async {
    // 🔊 Reproducir Sonido
    try {
      if (alertasSonorasActivas) {
        await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
      }
    } catch (e) {
      debugPrint("Error audio: $e");
    }

    // 👀 Mostrar Alerta Visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: MediaQuery.of(context).size.width > 600 ? 500 : null,
          backgroundColor: Colors.orange[900],
          duration: const Duration(seconds: 10),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "¡Reserva Próxima!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("$cliente llega en $minutos min."),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "VER",
            textColor: Colors.white,
            onPressed: () {
              if (onFiltroChanged != null) {
                onFiltroChanged!("confirmada");
              }
            },
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // ⚙️ ACTUALIZACIÓN DE ESTADOS
  // ===========================================================================
  /// Auto-ocupa una mesa cuando llega la hora de la reserva.
  /// 
  /// Actualiza el estado de la reserva a 'en_curso' y marca la mesa como ocupada.
  /// 
  /// Parámetros:
  /// - [reservaId]: ID de la reserva a procesar
  /// - [data]: Datos de la reserva
  Future<void> autoOcuparMesa(
    String reservaId,
    Map<String, dynamic> data,
  ) async {
    final reservaRef = FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .collection("reservas")
        .doc(reservaId);

    try {
      final snapshot = await reservaRef.get();

      // 🔒 PROTECCIÓN: verificación en tiempo real
      if (!snapshot.exists) return;

      final estadoActual = snapshot.data()?['estado'];
      if (estadoActual != 'confirmada') {
        return; // Ya fue procesada por otro ciclo
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1. Reserva → En curso
      batch.update(reservaRef, {"estado": "en_curso"});

      // 2. Mesa(s) → Ocupada(s) - Soporta múltiples mesas
      final mesaId = data['mesaId'];
      List<String> mesasIds = [];

      if (mesaId != null) {
        if (mesaId is List) {
          mesasIds = List<String>.from(mesaId);
        } else {
          mesasIds = [mesaId.toString()];
        }

        // Marcar todas las mesas como ocupadas
        for (final mesaIdStr in mesasIds) {
          final mesaRef = FirebaseFirestore.instance
              .collection("places")
              .doc(placeId)
              .collection("mesas")
              .doc(mesaIdStr);

          batch.update(mesaRef, {
            "estado": "ocupada",
            "clienteActivo": data['cliente'],
            "reservaIdActiva": reservaId,
          });
        }
      }

      await batch.commit();
      _alertedReservations.remove(reservaId);
      debugPrint("✅ Auto-ocupada reserva ${data['cliente']} ($reservaId)");
    } catch (e) {
      debugPrint("❌ Error auto-ocupando reserva $reservaId: $e");
    }
  }

  /// Actualiza el estado de una reserva y su mesa(s) asociada(s).
  /// 
  /// Soporta tanto una sola mesa como múltiples mesas.
  /// 
  /// Parámetros:
  /// - [context]: BuildContext para mostrar mensajes
  /// - [id]: ID de la reserva
  /// - [data]: Datos actuales de la reserva
  /// - [nuevoEstado]: Nuevo estado a asignar
  Future<void> updateEstado(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    String nuevoEstado,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final reservaRef = FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .collection("reservas")
        .doc(id);

    batch.update(reservaRef, {"estado": nuevoEstado});

    final mesaId = data['mesaId'];
    List<String> mesasIds = [];

    // Manejar tanto una sola mesa como múltiples mesas
    if (mesaId != null) {
      if (mesaId is List) {
        mesasIds = List<String>.from(mesaId);
      } else {
        mesasIds = [mesaId.toString()];
      }
    }

    if (mesasIds.isNotEmpty) {
      if (nuevoEstado == 'confirmada') {
        // Marcar todas las mesas como reservadas
        for (final mesaIdStr in mesasIds) {
          final mesaRef = FirebaseFirestore.instance
              .collection("places")
              .doc(placeId)
              .collection("mesas")
              .doc(mesaIdStr);

          batch.update(mesaRef, {
            "estado": "reservada",
            "reservaIdActiva": id,
          });
        }
      } else if (nuevoEstado == 'en_curso') {
        // Marcar todas las mesas como ocupadas
        for (final mesaIdStr in mesasIds) {
          final mesaRef = FirebaseFirestore.instance
              .collection("places")
              .doc(placeId)
              .collection("mesas")
              .doc(mesaIdStr);

          batch.update(mesaRef, {
            "estado": "ocupada",
            "clienteActivo": data['cliente'],
            "reservaIdActiva": id,
          });
        }
      } else if (nuevoEstado == 'rechazada' ||
          nuevoEstado == 'completada' ||
          nuevoEstado == 'no_asistio') {
        // Liberar todas las mesas asociadas
        for (final mesaIdStr in mesasIds) {
          final mesaRef = FirebaseFirestore.instance
              .collection("places")
              .doc(placeId)
              .collection("mesas")
              .doc(mesaIdStr);

          final mesaSnap = await mesaRef.get();
          final reservaActiva = mesaSnap.data()?['reservaIdActiva'];

          if (reservaActiva == id) {
            batch.update(mesaRef, {
              "estado": "libre",
              "clienteActivo": FieldValue.delete(),
              "reservaIdActiva": FieldValue.delete(),
            });
          }
        }
      }
    }

    await batch.commit();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Estado actualizado: ${nuevoEstado.toUpperCase()}"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
