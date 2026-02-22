import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barapp/models/place.dart';
import 'package:barapp/utils/venue_utils.dart';

/// Modal de formulario de reserva
/// 
/// Incluye validación de disponibilidad y check de compromiso
class ReservationFormModal {
  /// Muestra el modal de reserva con validación completa
  static void show(BuildContext context, Place place) {
    // Controladores y Valores Iniciales
    final personasCtrl = TextEditingController(text: '2');
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final user = FirebaseAuth.instance.currentUser!;

    // Variable para feedback visual (loading en el botón)
    bool checkingAvailability = false;
    bool acceptTerms = false; // 🔥 Check de compromiso

    // Guardar el contexto padre para mostrar SnackBars después de cerrar el modal
    final BuildContext parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reservar en ${place.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. INPUT CANTIDAD DE PERSONAS
                  const Text(
                    "Cantidad de personas",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: personasCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      prefixIcon: const Icon(
                        Icons.people,
                        color: Colors.orangeAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. SELECTORES DE FECHA Y HORA
                  Row(
                    children: [
                      // SELECCIONAR FECHA
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Colors.orangeAccent,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Fecha",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // SELECCIONAR HORA
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Colors.orangeAccent,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setModalState(() => selectedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Hora",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔥 3. CHECK DE COMPROMISO
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: acceptTerms
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: acceptTerms
                            ? Colors.green
                            : Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: acceptTerms,
                      onChanged: (v) =>
                          setModalState(() => acceptTerms = v ?? false),
                      title: const Text(
                        "Entendido y Acepto",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Me comprometo a asistir o cancelar con anticipación. Entiendo que hay 15 min de tolerancia.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      activeColor: Colors.greenAccent,
                      checkColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. BOTÓN CONFIRMAR (Deshabilitado si no acepta)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        disabledBackgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // 🔥 BLOQUEO: Si no acepta términos O está cargando -> null (deshabilitado)
                      onPressed: (checkingAvailability || !acceptTerms)
                          ? null
                          : () async {
                              final personasInput = personasCtrl.text.trim();
                              if (personasInput.isEmpty) return;
                              final personas = int.tryParse(personasInput) ?? 2;

                              // Mostrar indicador de carga mientras validamos
                              setModalState(() => checkingAvailability = true);

                              // 🔥 VALIDACIÓN 1: Verificar que los horarios estén configurados
                              final placeDoc = await FirebaseFirestore.instance
                                  .collection('places')
                                  .doc(place.id)
                                  .get();
                              final placeDataRaw = placeDoc.data() ?? {};
                              
                              final horarioApertura = placeDataRaw['horarioApertura'] as String?;
                              final horarioCierre = placeDataRaw['horarioCierre'] as String?;
                              
                              // Verificar que los horarios estén configurados
                              if (horarioApertura == null || 
                                  horarioCierre == null ||
                                  horarioApertura.isEmpty || 
                                  horarioCierre.isEmpty ||
                                  horarioApertura == '--:--' || 
                                  horarioCierre == '--:--') {
                                if (!parentContext.mounted) return;
                                // Cerrar el modal primero
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Este local aún no tiene configurado el servicio de reservas. "
                                        "Por favor, contacta al local directamente.",
                                      ),
                                      backgroundColor: Colors.orangeAccent,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                return;
                              }

                              // 🔥 VALIDACIÓN 2: Verificar que la fecha/hora de reserva esté dentro del horario de apertura
                              final fechaElegidaInicio = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              // Verificar si la hora de reserva está dentro del horario de apertura
                              if (!ReservationFormModal._estaDentroDelHorario(fechaElegidaInicio, placeDataRaw)) {
                                final formattedHours = VenueUtils.getFormattedHours(placeDataRaw);
                                if (!parentContext.mounted) return;
                                // Cerrar el modal primero
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "La reserva no está dentro del horario de apertura del local. "
                                      "Horarios: $formattedHours. Por favor, elige otro horario.",
                                    ),
                                    backgroundColor: Colors.orangeAccent,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                                return;
                              }

                              // Si llegamos aquí, las validaciones pasaron, continuamos con el proceso

                              try {
                                // Los datos del place y fechaElegidaInicio ya los tenemos arriba, reutilizamos

                                // Leemos la duración, si no existe usamos 120 por defecto
                                final int duracionMinutos =
                                    placeDataRaw['duracionPromedio'] ?? 120;

                                // Fecha Fin deseada (Calculada con la duración real)
                                final fechaElegidaFin = fechaElegidaInicio
                                    .add(Duration(minutes: duracionMinutos));

                                // 2. BUSCAR CONFLICTOS
                                final startOfDay = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  0,
                                  0,
                                );
                                final endOfDay = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  23,
                                  59,
                                );

                                final reservasDelDiaSnap =
                                    await FirebaseFirestore.instance
                                        .collection('places')
                                        .doc(place.id)
                                        .collection('reservas')
                                        .where(
                                          'fecha',
                                          isGreaterThanOrEqualTo:
                                              Timestamp.fromDate(startOfDay),
                                        )
                                        .where(
                                          'fecha',
                                          isLessThanOrEqualTo:
                                              Timestamp.fromDate(endOfDay),
                                        )
                                        .get();

                                final List<String> mesasOcupadasIds = [];

                                for (var doc in reservasDelDiaSnap.docs) {
                                  final data = doc.data();
                                  final String estado =
                                      data['estado'] ?? 'pendiente';

                                  // Si se fueron antes (completada) o fue rechazada, no cuenta como ocupada
                                  if (estado == 'rechazada' ||
                                      estado == 'completada') {
                                    continue;
                                  }

                                  // Chequeo de choque de horarios
                                  final DateTime existingInicio =
                                      (data['fecha'] as Timestamp).toDate();
                                  // Asumimos que las reservas existentes también respetan la duración promedio
                                  final DateTime existingFin = existingInicio
                                      .add(Duration(minutes: duracionMinutos));

                                  // FÓRMULA DE COLISIÓN
                                  final bool hayConflicto =
                                      (fechaElegidaInicio.isBefore(existingFin)) &&
                                          (fechaElegidaFin.isAfter(existingInicio));

                                  if (hayConflicto) {
                                    final mesaId = data['mesaId'];
                                    if (mesaId != null) {
                                      // Manejar tanto String como List<String>
                                      if (mesaId is List) {
                                        mesasOcupadasIds.addAll(
                                          List<String>.from(mesaId),
                                        );
                                      } else {
                                        mesasOcupadasIds.add(mesaId.toString());
                                      }
                                    }
                                  }
                                }

                                // 3. BUSCAR MESA DISPONIBLE O CALCULAR CAPACIDAD TOTAL
                                // Primero intentamos encontrar una mesa individual con capacidad suficiente
                                final mesasCandidatasSnap =
                                    await FirebaseFirestore.instance
                                        .collection('places')
                                        .doc(place.id)
                                        .collection('mesas')
                                        .where(
                                          'capacidad',
                                          isGreaterThanOrEqualTo: personas,
                                        )
                                        .orderBy('capacidad')
                                        .get();

                                QueryDocumentSnapshot? mesaAsignada;

                                for (var mesa in mesasCandidatasSnap.docs) {
                                  if (!mesasOcupadasIds.contains(mesa.id)) {
                                    mesaAsignada = mesa;
                                    break;
                                  }
                                }

                                // Si no encontramos una mesa individual, calculamos capacidad total disponible
                                if (mesaAsignada == null) {
                                  // Obtener todas las mesas libres en ese horario
                                  final todasLasMesasSnap =
                                      await FirebaseFirestore.instance
                                          .collection('places')
                                          .doc(place.id)
                                          .collection('mesas')
                                          .get();

                                  int capacidadTotalDisponible = 0;
                                  int capacidadMaximaIndividual = 0;
                                  int mesasLibres = 0;

                                  for (var mesa in todasLasMesasSnap.docs) {
                                    final capacidad = (mesa.data()['capacidad'] as num?)?.toInt() ?? 0;
                                    final estado = mesa.data()['estado'] ?? 'libre';
                                    
                                    // Contar capacidad máxima individual
                                    if (capacidad > capacidadMaximaIndividual) {
                                      capacidadMaximaIndividual = capacidad;
                                    }

                                    // Si la mesa no está ocupada en ese horario, sumar su capacidad
                                    if (!mesasOcupadasIds.contains(mesa.id) && 
                                        (estado == 'libre' || estado == 'reservada')) {
                                      capacidadTotalDisponible += capacidad;
                                      mesasLibres++;
                                    }
                                  }

                                  // Si la capacidad total es suficiente, permitir crear reserva sin mesa asignada
                                  if (capacidadTotalDisponible >= personas) {
                                    // Crear reserva sin mesa asignada - el dueño la asignará después
                                    mesaAsignada = null; // Se mantiene null para indicar sin mesa
                                  } else {
                                    // No hay suficiente capacidad total
                                    setModalState(() => checkingAvailability = false);
                                    if (context.mounted) {
                                      String mensaje;
                                      if (capacidadMaximaIndividual < personas) {
                                        mensaje = "No tenemos capacidad para $personas personas en ese horario. "
                                            "La mesa más grande tiene capacidad para $capacidadMaximaIndividual personas. "
                                            "Capacidad total disponible: $capacidadTotalDisponible personas.";
                                      } else {
                                        mensaje = "No hay disponibilidad para $personas personas en ese horario. "
                                            "Capacidad total disponible: $capacidadTotalDisponible personas "
                                            "($mesasLibres mesa${mesasLibres != 1 ? 's' : ''} libre${mesasLibres != 1 ? 's' : ''}).";
                                      }
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(mensaje),
                                          backgroundColor: Colors.redAccent,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }

                                // --- GUARDAR RESERVA ---
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(user.uid)
                                    .get();
                                final userData = userDoc.data();
                                final String realName = userData?['displayName'] ??
                                    user.displayName ??
                                    'Usuario App';
                                final String? realPhoto =
                                    userData?['imageUrl'] ?? user.photoURL;

                                final Map<String, dynamic> reservaData = {
                                  'cliente': realName,
                                  'userId': user.uid,
                                  'userAvatar': realPhoto ?? user.photoURL,
                                  'placeName': place.name,
                                  'personas': personas,
                                  'fecha': Timestamp.fromDate(fechaElegidaInicio),
                                  'estado': 'pendiente',
                                  'creadoEn': FieldValue.serverTimestamp(),
                                };

                                // Si hay mesa asignada, agregarla; si no, crear sin mesa (grupo grande)
                                String? nombreMesa;
                                if (mesaAsignada != null) {
                                  reservaData['mesaId'] = mesaAsignada.id;
                                  final mesaData = mesaAsignada.data() as Map<String, dynamic>?;
                                  nombreMesa = mesaData?['nombre'] as String?;
                                  reservaData['mesaNombre'] = nombreMesa;
                                } else {
                                  // Reserva sin mesa asignada - grupo grande que requiere múltiples mesas
                                  reservaData['mesaId'] = null;
                                  reservaData['mesaNombre'] = null;
                                }

                                await FirebaseFirestore.instance
                                    .collection('places')
                                    .doc(place.id)
                                    .collection('reservas')
                                    .add(reservaData);

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        mesaAsignada != null && nombreMesa != null
                                            ? "¡Solicitud enviada para la mesa $nombreMesa!"
                                            : "¡Solicitud enviada para $personas personas! "
                                                "El local te confirmará la asignación de mesas.",
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => checkingAvailability = false);
                                debugPrint("Error: $e");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              }
                            },
                      child: checkingAvailability
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              !acceptTerms
                                  ? "ACEPTA TÉRMINOS PRIMERO"
                                  : "SOLICITAR RESERVA",
                              style: TextStyle(
                                color:
                                    !acceptTerms ? Colors.white38 : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Verifica si una fecha/hora específica está dentro del horario de apertura del local
  static bool _estaDentroDelHorario(DateTime fechaHora, Map<String, dynamic> placeData) {
    final horarioApertura = placeData['horarioApertura'] as String?;
    final horarioCierre = placeData['horarioCierre'] as String?;
    final tieneDobleTurno = placeData['tieneDobleTurno'] ?? false;
    final horarioApertura2 = placeData['horarioApertura2'] as String?;
    final horarioCierre2 = placeData['horarioCierre2'] as String?;

    // Convertir la hora de la reserva a minutos desde medianoche
    final reservaMinutes = fechaHora.hour * 60 + fechaHora.minute;

    // Función helper para parsear hora a minutos
    int? parseTimeToMinutes(String? timeString) {
      if (timeString == null || timeString.isEmpty || timeString == '--:--') {
        return null;
      }
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null || hour < 0 || hour >= 24 || minute < 0 || minute >= 60) {
        return null;
      }
      return hour * 60 + minute;
    }

    // Función helper para verificar si está en rango
    bool isTimeInRange(int currentMinutes, int? startMinutes, int? endMinutes) {
      if (startMinutes == null || endMinutes == null) return false;
      
      // Si cruza medianoche (cierre < apertura)
      if (endMinutes < startMinutes) {
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
      } else {
        return currentMinutes >= startMinutes && currentMinutes < endMinutes;
      }
    }

    // Verificar primer turno
    final apertura1Minutes = parseTimeToMinutes(horarioApertura);
    final cierre1Minutes = parseTimeToMinutes(horarioCierre);

    if (apertura1Minutes == null || cierre1Minutes == null) {
      return false;
    }

    if (isTimeInRange(reservaMinutes, apertura1Minutes, cierre1Minutes)) {
      return true;
    }

    // Si tiene doble turno, verificar segundo turno
    if (tieneDobleTurno) {
      final apertura2Minutes = parseTimeToMinutes(horarioApertura2);
      final cierre2Minutes = parseTimeToMinutes(horarioCierre2);

      if (apertura2Minutes != null && cierre2Minutes != null) {
        if (isTimeInRange(reservaMinutes, apertura2Minutes, cierre2Minutes)) {
          return true;
        }
      }
    }

    return false;
  }
}
