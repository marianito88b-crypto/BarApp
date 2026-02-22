import 'package:flutter/material.dart';

/// Widget que muestra un badge con el estado de una reserva
class ReservaEstadoBadge extends StatelessWidget {
  final String estado;

  const ReservaEstadoBadge({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = estado.toUpperCase().replaceAll('_', ' ');
    switch (estado) {
      case 'confirmada':
        color = Colors.greenAccent;
        break;
      case 'en_curso':
        color = Colors.orangeAccent;
        break;
      case 'rechazada':
        color = Colors.redAccent;
        break;
      case 'completada':
        color = Colors.blueAccent;
        break;
      case 'no_asistio':
        color = Colors.grey;
        label = "NO ASISTIÓ";
        break;
      default:
        color = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
