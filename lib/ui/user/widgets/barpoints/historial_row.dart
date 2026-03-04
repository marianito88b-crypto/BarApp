import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fila del historial de movimientos de BarPoints.
///
/// - [monto] positivo → crédito (verde +N)
/// - [monto] negativo → débito (rojo -N)
/// - [fecha] opcional — si es null no se renderiza la fecha.
class HistorialRow extends StatelessWidget {
  final String concepto;
  final int monto;
  final DateTime? fecha;

  const HistorialRow({
    super.key,
    required this.concepto,
    required this.monto,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final isCredito = monto >= 0;
    final color = isCredito ? Colors.greenAccent : Colors.redAccent;
    final prefijo = isCredito ? '+' : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concepto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (fecha != null)
                  Text(
                    DateFormat('dd/MM/yy').format(fecha!),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$prefijo$monto',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
