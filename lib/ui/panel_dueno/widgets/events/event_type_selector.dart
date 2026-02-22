import 'package:flutter/material.dart';

/// Selector de tipo de evento (Show o Promo)
class EventTypeSelector extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const EventTypeSelector({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final color = value == 'show' ? Colors.amber : Colors.greenAccent;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
