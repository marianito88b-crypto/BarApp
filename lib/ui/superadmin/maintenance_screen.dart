import 'package:flutter/material.dart';
import '../../services/maintenance_service.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Ejecutar Limpieza General",
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Esta operación ejecutará una limpieza completa del sistema:",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              "📋 Operaciones a realizar:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "• Eliminar historias con más de 24hs\n"
              "• Eliminar archivos de Storage asociados\n"
              "• Eliminar usuarios invitados antiguos (>24hs)\n"
              "• Limpiar pedidos de locales con más de 90 días (3 meses)\n"
              "• Validación de seguridad: No borra datos operativos recientes",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              "⚠️ ADVERTENCIA:",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "• Esta acción es irreversible\n"
              "• Eliminará datos antiguos para optimizar el rendimiento\n"
              "• El proceso puede tardar varios minutos\n"
              "• Revisa los logs en la consola para el progreso",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              "¿Estás seguro de continuar?",
              style: TextStyle(
                color: Colors.white,
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
              _executeCleanup(ctx);
            },
            child: const Text("EJECUTAR LIMPIEZA"),
          ),
        ],
      ),
    );
  }

  void _executeCleanup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _MaintenanceProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Mantenimiento de Sistema'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Mantenimiento del Sistema",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "El sistema de mantenimiento ayuda a optimizar el rendimiento "
                      "eliminando datos antiguos y archivos basura de forma segura.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCleanupDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cleaning_services, size: 28),
              label: const Text(
                "Ejecutar Limpieza General",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Operaciones incluidas:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationItem(
                      Icons.auto_stories,
                      "Historias antiguas",
                      "Elimina historias con más de 24 horas de antigüedad y sus archivos asociados",
                    ),
                    const SizedBox(height: 12),
                    _buildOperationItem(
                      Icons.person_off,
                      "Usuarios invitados",
                      "Elimina usuarios invitados con más de 24 horas desde su creación",
                    ),
                    const SizedBox(height: 12),
                    _buildOperationItem(
                      Icons.storage,
                      "Archivos de Storage",
                      "Elimina archivos huérfanos en Firebase Storage",
                    ),
                    const SizedBox(height: 12),
                    _buildOperationItem(
                      Icons.receipt_long,
                      "Pedidos de locales",
                      "Elimina pedidos con más de 90 días (3 meses) de todos los locales",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Diálogo que muestra el progreso de la limpieza
class _MaintenanceProgressDialog extends StatefulWidget {
  const _MaintenanceProgressDialog();

  @override
  State<_MaintenanceProgressDialog> createState() =>
      _MaintenanceProgressDialogState();
}

class _MaintenanceProgressDialogState
    extends State<_MaintenanceProgressDialog> {
  bool _isRunning = true;
  String _status = 'Iniciando limpieza...';
  MaintenanceResult? _results;

  @override
  void initState() {
    super.initState();
    _runCleanup();
  }

  Future<void> _runCleanup() async {
    try {
      setState(() => _status = 'Obteniendo datos...');

      final results = await MaintenanceService.executeFullCleanup(
        onProgress: (status) {
          if (mounted) {
            setState(() => _status = status);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isRunning = false;
          _results = results;
          _status = 'Limpieza completada';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        "Limpieza en Progreso",
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRunning) ...[
            const CircularProgressIndicator(color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Revisa la consola para ver el progreso detallado",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (_results != null) ...[
            Icon(
              _results!.errors > 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle,
              color: _results!.errors > 0
                  ? Colors.orangeAccent
                  : Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildStatRow('✅ Historias borradas', _results!.storiesDeleted,
                      Colors.greenAccent),
                  _buildStatRow('✅ Usuarios limpiados', _results!.usersDeleted,
                      Colors.blueAccent),
                  _buildStatRow('✅ Archivos Storage', _results!.filesDeleted,
                      Colors.purpleAccent),
                  _buildStatRow('✅ Pedidos eliminados', _results!.ordersDeleted,
                      Colors.orangeAccent),
                  if (_results!.errors > 0)
                    _buildStatRow('❌ Errores', _results!.errors,
                        Colors.redAccent),
                  const Divider(color: Colors.white10),
                  _buildStatRow('Total eliminado', _results!.totalDeleted,
                      Colors.orangeAccent, isBold: true),
                ],
              ),
            ),
          ] else ...[
            const Icon(Icons.error, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isRunning)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Cerrar"),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value, Color color,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
