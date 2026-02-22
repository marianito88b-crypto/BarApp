import 'package:flutter/material.dart';

/// Widget tile reutilizable para opciones de configuración
class ConfigTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const ConfigTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: Colors.white70),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white24,
            ),
      ),
    );
  }
}
