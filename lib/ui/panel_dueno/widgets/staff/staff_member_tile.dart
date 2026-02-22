import 'package:flutter/material.dart';
import 'staff_role_badge.dart';
import 'staff_helpers.dart';
import 'modals/attendance_history_dialog.dart';

/// Tile que muestra la información de un miembro del staff en el layout móvil
class StaffMemberTile extends StatelessWidget {
  final String uid;
  final String email;
  final String? rol;
  final String placeId;
  final Map<String, dynamic>? staffData; // Datos completos del staff
  final VoidCallback onDelete;

  const StaffMemberTile({
    super.key,
    required this.uid,
    required this.email,
    this.rol,
    required this.placeId,
    this.staffData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rolValue = rol ?? 'mozo';
    final color = getColorRol(rolValue);
    final icon = getIconRol(rolValue);

    // Obtener nombre a mostrar (apodo si existe, sino nombre completo)
    final nombreCompleto = staffData?['nombre'] ?? staffData?['nombreCompleto'] ?? email;
    final apodo = staffData?['apodo'] as String?;
    final nombreAMostrar = apodo != null && apodo.isNotEmpty ? apodo : nombreCompleto;
    
    // Obtener foto del staff o del usuario
    final fotoUrl = staffData?['fotoUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withValues(alpha: 0.2),
          backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
              ? NetworkImage(fotoUrl)
              : null,
          child: fotoUrl == null || fotoUrl.isEmpty
              ? Icon(icon, color: color, size: 24)
              : null,
        ),
        title: Text(
          nombreAMostrar,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleBadge(rol: rolValue),
              if (apodo != null && apodo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.orangeAccent),
              onPressed: () => AttendanceHistoryDialog.show(
                context,
                placeId,
                uid,
                email,
              ),
              tooltip: "Ver historial",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: "Eliminar acceso",
            ),
          ],
        ),
      ),
    );
  }
}
