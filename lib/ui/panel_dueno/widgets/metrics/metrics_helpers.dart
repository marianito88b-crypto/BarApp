import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const Badge({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double amount;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "\$${NumberFormat.compact().format(amount)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const InfoRow(
    this.label,
    this.value,
    this.color, {
    super.key,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
