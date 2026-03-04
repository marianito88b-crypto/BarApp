import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../logic/staff_logic.dart';

/// Diálogo que muestra el historial de asistencias de un colaborador
class AttendanceHistoryDialog extends StatefulWidget {
  final String placeId;
  final String uidStaff;
  final String email;

  const AttendanceHistoryDialog({
    super.key,
    required this.placeId,
    required this.uidStaff,
    required this.email,
  });

  /// Método estático para mostrar el diálogo de forma conveniente
  static Future<void> show(
    BuildContext context,
    String placeId,
    String uidStaff,
    String email,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => AttendanceHistoryDialog(
        placeId: placeId,
        uidStaff: uidStaff,
        email: email,
      ),
    );
  }

  @override
  State<AttendanceHistoryDialog> createState() => _AttendanceHistoryDialogState();
}

class _AttendanceHistoryDialogState extends State<AttendanceHistoryDialog> with StaffLogicMixin {
  @override
  String get placeId => widget.placeId;

  // Hora de referencia para considerar llegada tarde (ej: 9:00 AM)
  static const int horaReferencia = 9;
  static const int minutoReferencia = 0;
  
  bool _isExporting = false;
  bool _isCleaning = false;
  late final Stream<QuerySnapshot> _asistenciasStream;

  @override
  void initState() {
    super.initState();
    _asistenciasStream = getAsistenciasStream(widget.uidStaff);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Colors.orangeAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                "Historial de Asistencias",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Mensaje informativo sobre límite de 1 mes
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "El registro se guarda por 1 mes. Te recomendamos exportar y guardar la planilla si querés conservar el registro por mayor tiempo.",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500,
        child: StreamBuilder<QuerySnapshot>(
          stream: _asistenciasStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 60,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Sin registros de asistencia",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            }

            // Agrupar asistencias por fecha
            final Map<String, Map<String, dynamic>> asistenciasPorDia = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              if (timestamp == null) continue;

              final fecha = timestamp.toDate();
              final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
              final tipo = data['tipo'] as String? ?? 'entrada';

              if (!asistenciasPorDia.containsKey(fechaKey)) {
                asistenciasPorDia[fechaKey] = {
                  'entrada': null,
                  'salida': null,
                  'fecha': fecha,
                };
              }

              asistenciasPorDia[fechaKey]![tipo] = fecha;
            }

            // Convertir a lista y ordenar por fecha descendente
            final listaDias = asistenciasPorDia.entries.toList()
              ..sort((a, b) => b.value['fecha'].compareTo(a.value['fecha']));

            return ListView.separated(
              itemCount: listaDias.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final entry = listaDias[index];
                final fecha = entry.value['fecha'] as DateTime;
                final entrada = entry.value['entrada'] as DateTime?;
                final salida = entry.value['salida'] as DateTime?;

                // Verificar si llegó tarde
                bool llegoTarde = false;
                if (entrada != null) {
                  final horaEntrada = entrada.hour * 60 + entrada.minute;
                  final horaRef = horaReferencia * 60 + minutoReferencia;
                  llegoTarde = horaEntrada > horaRef;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      // Fecha
                      SizedBox(
                        width: 100,
                        child: Text(
                          DateFormat('dd/MM/yy').format(fecha),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Entrada
                      Expanded(
                        child: _buildTimeCell(
                          entrada,
                          'Entrada',
                          llegoTarde,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Salida
                      Expanded(
                        child: _buildTimeCell(
                          salida,
                          'Salida',
                          false,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        // Botón de exportar
        TextButton.icon(
          onPressed: _isExporting ? null : _exportToCsv,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orangeAccent,
                  ),
                )
              : const Icon(Icons.download, color: Colors.orangeAccent, size: 18),
          label: Text(
            _isExporting ? "Exportando..." : "Exportar",
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
        // Botón de limpiar
        TextButton.icon(
          onPressed: _isCleaning ? null : _showCleanDialog,
          icon: _isCleaning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                )
              : const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
          label: Text(
            _isCleaning ? "Limpiando..." : "Limpiar",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Cerrar",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCell(DateTime? hora, String label, bool isLate) {
    if (hora == null) {
      return Text(
        '-',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 14,
        ),
      );
    }

    final horaStr = DateFormat('HH:mm').format(hora);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          horaStr,
          style: TextStyle(
            color: isLate ? Colors.redAccent : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isLate)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tarde',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Exporta el historial de asistencias a un archivo CSV
  Future<void> _exportToCsv() async {
    setState(() => _isExporting = true);

    try {
      // Obtener todas las asistencias del colaborador
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('asistencias')
          .where('uidStaff', isEqualTo: widget.uidStaff)
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay asistencias para exportar"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      // Construir CSV
      final StringBuffer csv = StringBuffer();
      csv.writeln('Fecha,Entrada,Salida,Tipo');

      // Agrupar por fecha
      final Map<String, Map<String, DateTime?>> asistenciasPorDia = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp == null) continue;

        final fecha = timestamp.toDate();
        final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
        final tipo = data['tipo'] as String? ?? 'entrada';

        if (!asistenciasPorDia.containsKey(fechaKey)) {
          asistenciasPorDia[fechaKey] = {
            'entrada': null,
            'salida': null,
            'fecha': fecha,
          };
        }

        if (tipo == 'entrada') {
          asistenciasPorDia[fechaKey]!['entrada'] = fecha;
        } else {
          asistenciasPorDia[fechaKey]!['salida'] = fecha;
        }
      }

        // Escribir al CSV
      final listaDias = asistenciasPorDia.entries.toList()
        ..sort((a, b) => a.value['fecha']!.compareTo(b.value['fecha']!));

      for (var entry in listaDias) {
        final fecha = entry.value['fecha'] as DateTime;
        final entrada = entry.value['entrada'];
        final salida = entry.value['salida'];

        csv.writeln(
          '${DateFormat('dd/MM/yyyy').format(fecha)},'
          '${entrada != null ? DateFormat('HH:mm').format(entrada) : '-'},'
          '${salida != null ? DateFormat('HH:mm').format(salida) : '-'},'
          '${entrada != null && salida != null ? "Completo" : entrada != null ? "Solo Entrada" : "Solo Salida"}',
        );
      }

      // Copiar al portapapeles y mostrar opción para compartir
      await Clipboard.setData(ClipboardData(text: csv.toString()));

      if (mounted) {
        // Mostrar diálogo con opción de copiar o ver contenido
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  "Exportación Completada",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "El contenido CSV ha sido copiado al portapapeles.",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Puedes pegarlo en Excel o Google Sheets.",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv.toString(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cerrar",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error exportando CSV: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// Muestra diálogo de confirmación para limpiar asistencias antiguas
  void _showCleanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text(
              "Limpiar Registros Antiguos",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "El registro se guarda por 1 mes. Te recomendamos exportar y guardar la planilla si querés conservar el registro por mayor tiempo.",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "¿Deseas eliminar todas las asistencias mayores a 1 mes?",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              "Esta acción no se puede deshacer.",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cleanOldAttendances();
            },
            child: const Text("Limpiar Registros"),
          ),
        ],
      ),
    );
  }

  /// Limpia las asistencias mayores a 1 mes
  Future<void> _cleanOldAttendances() async {
    setState(() => _isCleaning = true);

    try {
      final unMesAtras = DateTime.now().subtract(const Duration(days: 30));
      final timestampLimite = Timestamp.fromDate(unMesAtras);

      // Obtener todas las asistencias antiguas
      final oldAttendances = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('asistencias')
          .where('uidStaff', isEqualTo: widget.uidStaff)
          .where('timestamp', isLessThan: timestampLimite)
          .get();

      if (oldAttendances.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay registros antiguos para eliminar"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      // Eliminar en batch
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in oldAttendances.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${oldAttendances.docs.length} registros antiguos eliminados"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error limpiando asistencias: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al limpiar registros"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCleaning = false);
      }
    }
  }
}
