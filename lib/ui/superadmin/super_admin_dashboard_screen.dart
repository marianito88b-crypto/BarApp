import 'package:flutter/material.dart';
import 'manage_places_screen.dart';
import '../admin/reports_admin_screen.dart';
import 'notifications_admin_screen.dart';
import 'users_admin_screen.dart';
import 'maintenance_screen.dart';
import 'coupon_manager_screen.dart';
import '../../utils/migrate_places_ids.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  void _showMigrationDialog(BuildContext context) {
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
                "Migración de IDs de Places",
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
              "Esta operación migrará todos los IDs de documentos en la colección 'places' a slugs basados en el nombre.",
              style: TextStyle(color: Colors.white70),
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
              "• Esta operación NO se puede deshacer\n"
              "• Los documentos antiguos serán ELIMINADOS\n"
              "• Todas las subcolecciones serán copiadas\n"
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
              _executeMigration(ctx);
            },
            child: const Text("EJECUTAR MIGRACIÓN"),
          ),
        ],
      ),
    );
  }

  void _executeMigration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _MigrationProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 Super Admin'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          children: [
            _AdminCard(
              icon: Icons.store,
              title: 'Bares',
              subtitle: 'Planes, límites, control',
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagePlacesScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.report,
              title: 'Reportes',
              subtitle: 'Usuarios y comunidad',
              color: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsAdminScreen(),
                  ),
                );
              },
            ),
          _AdminCard(
  icon: Icons.notifications_active,
  title: 'Notificaciones',
  subtitle: 'Límites y uso',
  color: Colors.purpleAccent,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsAdminScreen(),
      ),
    );
  },
),
          _AdminCard(
  icon: Icons.people_alt_rounded,
  title: 'Usuarios',
  subtitle: 'Control global',
  color: Colors.cyanAccent,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UsersAdminScreen(),
      ),
    );
  },
),
          _AdminCard(
            icon: Icons.swap_horiz,
            title: 'Migrar IDs',
            subtitle: 'Normalizar IDs de places',
            color: Colors.amberAccent,
            onTap: () => _showMigrationDialog(context),
          ),
          _AdminCard(
            icon: Icons.cleaning_services,
            title: 'Mantenimiento',
            subtitle: 'Limpieza de datos y archivos',
            color: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MaintenanceScreen(),
                ),
              );
            },
          ),
          _AdminCard(
            icon: Icons.card_giftcard,
            title: 'Cupones',
            subtitle: 'Gestión de códigos de descuento',
            color: Colors.orangeAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CouponManagerScreen(),
                ),
              );
            },
          ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(icon, size: 48, color: color),
    const SizedBox(height: 12),

    Flexible(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    const SizedBox(height: 6),

    Flexible(
      child: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    ),
  ],
),
      ),
    );
  }
}

/// Diálogo que muestra el progreso de la migración
class _MigrationProgressDialog extends StatefulWidget {
  const _MigrationProgressDialog();

  @override
  State<_MigrationProgressDialog> createState() => _MigrationProgressDialogState();
}

class _MigrationProgressDialogState extends State<_MigrationProgressDialog> {
  bool _isRunning = true;
  String _status = 'Iniciando migración...';
  Map<String, int>? _results;

  @override
  void initState() {
    super.initState();
    _runMigration();
  }

  Future<void> _runMigration() async {
    try {
      setState(() => _status = 'Obteniendo documentos...');
      
      final results = await PlacesIdMigration.migrateAllPlaces();
      
      if (mounted) {
        setState(() {
          _isRunning = false;
          _results = results;
          _status = 'Migración completada';
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
        "Migración en Progreso",
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRunning) ...[
            const CircularProgressIndicator(color: Colors.amberAccent),
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
              _results!['errors']! > 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle,
              color: _results!['errors']! > 0
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
                  _buildStatRow('Total procesados', _results!['total']!),
                  _buildStatRow('✅ Migrados', _results!['migrated']!,
                      Colors.greenAccent),
                  _buildStatRow('⏭ Saltados', _results!['skipped']!,
                      Colors.orangeAccent),
                  if (_results!['errors']! > 0)
                    _buildStatRow('❌ Errores', _results!['errors']!,
                        Colors.redAccent),
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
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("Cerrar"),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}