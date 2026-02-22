import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar información detallada con icono, label y valor
class CajaInfoDetalle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const CajaInfoDetalle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white54)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una fila de información con label y monto formateado
class CajaInfoRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final double scale;

  const CajaInfoRow({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14 * scale,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              "\$${NumberFormat("#,##0", "es_AR").format(amount)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 16 * scale,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
