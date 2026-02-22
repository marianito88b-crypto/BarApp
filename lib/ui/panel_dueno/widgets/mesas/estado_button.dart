import 'package:flutter/material.dart';

/// Botón que representa un estado de mesa (LIBRE, OCUPADA, PAGADA, RESERVADA)
class EstadoButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const EstadoButton({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
              color: isSelected ? color : Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
