import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget que muestra un badge con timer en vivo que se actualiza cada minuto
/// Muestra el tiempo transcurrido desde la ocupación de una mesa
class LiveTimerBadge extends StatefulWidget {
  final Timestamp inicio;
  final bool isPagada;

  const LiveTimerBadge({
    super.key,
    required this.inicio,
    required this.isPagada,
  });

  @override
  State<LiveTimerBadge> createState() => _LiveTimerBadgeState();
}

class _LiveTimerBadgeState extends State<LiveTimerBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Actualiza el widget cada 60 segundos
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duration = now.difference(widget.inicio.toDate());
    if (duration.isNegative) return const SizedBox.shrink();

    final horas = duration.inHours;
    final minutos = duration.inMinutes % 60;

    Color colorTiempo = widget.isPagada
        ? Colors.blueAccent
        : (horas >= 1
            ? (horas >= 2 ? Colors.redAccent : Colors.orangeAccent)
            : Colors.greenAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorTiempo)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              widget.isPagada
                  ? Icons.attach_money
                  : Icons.access_time_filled,
              size: 10,
              color: colorTiempo),
          const SizedBox(width: 4),
          Text("${horas}h ${minutos}m",
              style: TextStyle(
                  color: colorTiempo,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
