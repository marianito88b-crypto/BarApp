import 'package:flutter/material.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final double? numericValue;
  final IconData icon;
  final Color color;
  final double? prevValue;
  final bool isMoney;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.numericValue,
    this.prevValue,
    this.isMoney = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos porcentaje de crecimiento simple
    String? growthText;
    Color growthColor = Colors.grey;

    if (numericValue != null && prevValue != null && prevValue! > 0) {
      double growth = ((numericValue! - prevValue!) / prevValue!) * 100;

      if (growth > 0) {
        growthText = "+${growth.toStringAsFixed(1)}%";
        growthColor = Colors.green;
      } else {
        growthText = "${growth.toStringAsFixed(1)}%";
        growthColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (growthText != null)
                Text(
                  growthText,
                  style: TextStyle(
                    color: growthColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
