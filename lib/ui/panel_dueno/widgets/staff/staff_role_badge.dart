import 'package:flutter/material.dart';
import 'staff_helpers.dart';

/// Badge que muestra el rol de un miembro del staff con color e icono
class RoleBadge extends StatelessWidget {
  final String rol;

  const RoleBadge({
    super.key,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final color = getColorRol(rol);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            rol.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
