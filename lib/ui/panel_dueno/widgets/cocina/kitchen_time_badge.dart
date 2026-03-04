import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el tiempo de creación de una comanda
///
/// Muestra la hora en formato HH:mm y los minutos transcurridos si pasaron más de 5 minutos.
/// Cambia de color cuando pasan más de 15 minutos.
///
/// IMPORTANTE: Es StatefulWidget con Timer para que el contador realmente avance
/// en pantalla sin depender de que el stream de Firestore emita un nuevo evento.
class KitchenTimeBadge extends StatefulWidget {
  final DateTime fecha;

  const KitchenTimeBadge({
    super.key,
    required this.fecha,
  });

  @override
  State<KitchenTimeBadge> createState() => _KitchenTimeBadgeState();
}

class _KitchenTimeBadgeState extends State<KitchenTimeBadge> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresca cada 30 segundos para que el contador sea preciso
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat("HH:mm").format(widget.fecha);
    final diff = DateTime.now().difference(widget.fecha).inMinutes;
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
