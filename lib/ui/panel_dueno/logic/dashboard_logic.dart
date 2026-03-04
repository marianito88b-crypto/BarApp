import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barapp/services/printer/printer_service.dart';
import 'package:barapp/services/dashboard/dashboard_metrics_service.dart';
import 'package:barapp/ui/panel_dueno/sections/dashboard_mobile.dart';

/// Mixin con la lógica de tiempos, notificaciones y auto-impresión del dashboard.
mixin DashboardLogic on State<DashboardMobile> {
  Timer? _refreshTimer;
  late DateTime _startOfDay;
  late DateTime _endOfDay;
  late Stream<QuerySnapshot> _salesStream;

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _reservasSub;
  StreamSubscription? _pedidosSub;
  StreamSubscription? _reservaPrintSub;
  StreamSubscription? _comandaPrintSub;
  StreamSubscription? _pedidoWebPrintSub;
  StreamSubscription? _salesCacheSub;

  Set<String> _knownReservasIds = {};
  Set<String> _knownPedidosIds = {};
  bool _isFirstLoad = true;

  /// Preferencias cargadas una sola vez para evitar lecturas de disco en streams.
  bool _autoPrintComandas = false;
  bool _autoPrintReservas = false;

  bool _dashboardLogicReady = false;
  bool get isDashboardLogicReady => _dashboardLogicReady;

  DateTime get startOfDay => _startOfDay;
  DateTime get endOfDay => _endOfDay;
  Stream<QuerySnapshot> get salesStream => _salesStream;

  /// Inicializa la lógica del dashboard. Cargar SharedPreferences aquí una sola vez.
  Future<void> initDashboardLogic() async {
    final prefs = await SharedPreferences.getInstance();
    _autoPrintComandas = prefs.getBool('autoPrintComandas') ?? false;
    _autoPrintReservas = prefs.getBool('autoPrintReservas') ?? false;

    calculateGastronomicDay();
    initSalesStream();
    initNotificationListeners();
    startShiftResetTimer();

    _comandaPrintSub = setupAutoPrintComandas(widget.placeId);
    _reservaPrintSub = setupAutoPrintReservas(widget.placeId);
    _pedidoWebPrintSub = setupAutoPrintPedidosWeb(widget.placeId);

    _dashboardLogicReady = true;
    if (mounted) setState(() {});
  }

  /// Cancela todas las suscripciones y timers del dashboard.
  void disposeDashboardLogic() {
    _refreshTimer?.cancel();
    _reservasSub?.cancel();
    _pedidosSub?.cancel();
    _reservaPrintSub?.cancel();
    _comandaPrintSub?.cancel();
    _pedidoWebPrintSub?.cancel();
    _salesCacheSub?.cancel();
    _audioPlayer.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tiempos (jornada gastronómica)
  // ---------------------------------------------------------------------------

  void calculateGastronomicDay() {
    const int horaCorte = 6;
    final now = DateTime.now();
    DateTime fechaNegocio;

    if (now.hour < horaCorte) {
      fechaNegocio = now.subtract(const Duration(days: 1));
    } else {
      fechaNegocio = now;
    }

    _startOfDay = DateTime(
      fechaNegocio.year,
      fechaNegocio.month,
      fechaNegocio.day,
      horaCorte,
      0,
      0,
    );
    _endOfDay = _startOfDay
        .add(const Duration(hours: 24))
        .subtract(const Duration(seconds: 1));
  }

  void initSalesStream() {
    _salesCacheSub?.cancel();
    _salesStream = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("ventas")
        .where(
          "fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay),
        )
        .where("fecha", isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay))
        .orderBy("fecha", descending: true)
        .snapshots();
    _salesCacheSub = _salesStream.listen((_) {
      DashboardMetricsService.clearCache();
    });
  }

  void startShiftResetTimer() {
    _refreshTimer?.cancel();

    final now = DateTime.now();
    DateTime next6AM = DateTime(now.year, now.month, now.day, 6, 1);
    if (now.isAfter(next6AM)) {
      next6AM = next6AM.add(const Duration(days: 1));
    }

    final timeUntilReset = next6AM.difference(now);

    _refreshTimer = Timer(timeUntilReset, () {
      if (mounted) {
        setState(() {
          calculateGastronomicDay();
          initSalesStream();
          startShiftResetTimer();
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Listeners de notificaciones
  // ---------------------------------------------------------------------------

  void initNotificationListeners() {
    _reservasSub = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("reservas")
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snap) {
      _checkNewItems(
        snap,
        _knownReservasIds,
        "¡Nueva Reserva Recibida!",
        Colors.blueAccent,
      );
      _knownReservasIds = snap.docs.map((d) => d.id).toSet();
    });

    _pedidosSub = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("orders")
        .where('estado', whereIn: ['pendiente', 'confirmado'])
        .where('origen', isEqualTo: 'app')
        .snapshots()
        .listen((snap) {
      _checkNewItems(
        snap,
        _knownPedidosIds,
        "¡Nuevo Pedido Web!",
        Colors.greenAccent,
      );
      _knownPedidosIds = snap.docs.map((d) => d.id).toSet();
    });

    // Garantiza que _isFirstLoad se libere después de 3 segundos,
    // independientemente de si los streams emiten (p.ej. bar sin pedidos online).
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _isFirstLoad = false;
    });
  }

  void _checkNewItems(
    QuerySnapshot snap,
    Set<String> knownIds,
    String message,
    Color color,
  ) {
    if (_isFirstLoad) return;

    final currentIds = snap.docs.map((d) => d.id).toSet();
    final newItems = currentIds.difference(knownIds);

    if (newItems.isNotEmpty) {
      _playAlertSound();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      debugPrint("Error audio dashboard: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-Print (devuelven StreamSubscription para cancelar)
  // ---------------------------------------------------------------------------

  StreamSubscription<QuerySnapshot> setupAutoPrintComandas(String placeId) {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('comandas')
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snapshot) async {
          if (!_autoPrintComandas) return;

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              final data = change.doc.data();

              if (data != null && data['impreso'] != true) {
                try {
                  // Transacción: reclamar impresión atómicamente para evitar duplicados
                  final claimed = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
                    final freshDoc = await transaction.get(change.doc.reference);
                    if (freshDoc.exists && freshDoc.data()?['impreso'] != true) {
                      transaction.update(change.doc.reference, {'impreso': true});
                      return true;
                    }
                    return false;
                  });

                  if (claimed) {
                    _playAlertSound();
                    // Impresión separada del claim: si falla, revertimos el flag
                    // para que el próximo ciclo del stream lo intente de nuevo.
                    try {
                      await PrinterService().printComanda(data);
                    } catch (printErr) {
                      debugPrint("❌ Error imprimiendo comanda: $printErr");
                      try {
                        await change.doc.reference.update({'impreso': false});
                      } catch (_) {}
                    }
                  }
                } catch (e) {
                  debugPrint("❌ Error en Auto-Print Comandas: $e");
                }
              }
            }
          }
        });
  }

  StreamSubscription<QuerySnapshot> setupAutoPrintReservas(String placeId) {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reservas')
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snapshot) async {
          if (!_autoPrintReservas) return;

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();

              if (data != null && data['impreso'] != true) {
                try {
                  // Transacción: reclamar impresión atómicamente
                  final claimed = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
                    final freshDoc = await transaction.get(change.doc.reference);
                    if (freshDoc.exists && freshDoc.data()?['impreso'] != true) {
                      transaction.update(change.doc.reference, {'impreso': true});
                      return true;
                    }
                    return false;
                  });

                  if (claimed) {
                    // Impresión separada del claim: si falla, revertimos el flag
                    // para que el próximo ciclo del stream lo intente de nuevo.
                    try {
                      await PrinterService().printTicket({
                        'tipoTicket': 'RESERVA',
                        'cliente': data['cliente'],
                        'mesaNombre': data['mesaNombre'] ?? 'A DEFINIR',
                        'fechaReserva': data['fecha'],
                        'personas': data['personas'] ?? 0,
                        'total': (data['costoReserva'] ?? 0).toDouble(),
                      });
                    } catch (printErr) {
                      debugPrint("❌ Error imprimiendo reserva: $printErr");
                      try {
                        await change.doc.reference.update({'impreso': false});
                      } catch (_) {}
                    }
                  }
                } catch (e) {
                  debugPrint("❌ Error en Auto-Print Reservas: $e");
                }
              }
            }
          }
        });
  }

  StreamSubscription<QuerySnapshot> setupAutoPrintPedidosWeb(String placeId) {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('orders')
        .where('estado', isEqualTo: 'confirmado')
        .where('origen', isEqualTo: 'app')
        .snapshots()
        .listen((snapshot) async {
          if (!_autoPrintComandas) return;

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();

              if (data != null && data['impreso'] != true) {
                try {
                  // Transacción: reclamar impresión atómicamente
                  final claimed = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
                    final freshDoc = await transaction.get(change.doc.reference);
                    if (freshDoc.exists && freshDoc.data()?['impreso'] != true) {
                      transaction.update(change.doc.reference, {'impreso': true});
                      return true;
                    }
                    return false;
                  });

                  if (claimed) {
                    _playAlertSound();
                    // Impresión separada del claim: si falla, revertimos el flag
                    // para que el próximo ciclo del stream lo intente de nuevo.
                    try {
                      await PrinterService().printComanda({
                        ...data,
                        'origen': 'app',
                        'mesaNombre':
                            data['metodoEntrega'] == 'delivery' ? 'DELIVERY' : 'RETIRO',
                      });

                      final telVal = data['clienteTelefono'] ?? data['telefono'];
                      final telTicket = (telVal != null &&
                              telVal.toString().trim().isNotEmpty &&
                              telVal.toString().toLowerCase() != 'null')
                          ? telVal.toString()
                          : 'S/D';
                      await PrinterService().printTicket({
                        ...data,
                        'tipoTicket': 'PEDIDO_CLIENTE',
                        'orderId': change.doc.id,
                        'cliente': data['clienteNombre'] ?? 'Cliente BarApp',
                        'telefono': telTicket,
                        'direccion': data['direccion'] ?? 'Retira en Local',
                        'total': (data['total'] as num?)?.toDouble() ?? 0.0,
                        'costoEnvio': (data['costoEnvio'] as num?)?.toDouble() ?? 0.0,
                      });
                    } catch (printErr) {
                      debugPrint("❌ Error imprimiendo pedido web: $printErr");
                      try {
                        await change.doc.reference.update({'impreso': false});
                      } catch (_) {}
                    }
                  }
                } catch (e) {
                  debugPrint("❌ Error en Auto-Print Pedidos Web: $e");
                }
              }
            }
          }
        });
  }
}
