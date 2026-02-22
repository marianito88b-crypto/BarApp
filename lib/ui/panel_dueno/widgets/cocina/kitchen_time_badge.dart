import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el tiempo de creación de una comanda
/// 
/// Muestra la hora en formato HH:mm y los minutos transcurridos si pasaron más de 5 minutos.
/// Cambia de color cuando pasan más de 15 minutos.
class KitchenTimeBadge extends StatelessWidget {
  final DateTime fecha;

  const KitchenTimeBadge({
    super.key,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat("HH:mm").format(fecha);
    final diff = DateTime.now().difference(fecha).inMinutes;
    Color bgColor = diff > 15 ? Colors.redAccent : Colors.black26;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (diff > 5) ...[
            const SizedBox(width: 6),
            Text("+$diff m", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
