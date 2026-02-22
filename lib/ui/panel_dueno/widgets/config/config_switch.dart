import 'package:flutter/material.dart';

/// Widget switch reutilizable para configuraciones
class ConfigSwitch extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool value;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const ConfigSwitch({
    super.key,
    required this.label,
    required this.subLabel,
    required this.value,
    required this.icon,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subLabel,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
