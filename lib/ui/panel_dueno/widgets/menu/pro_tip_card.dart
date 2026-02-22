import 'package:flutter/material.dart';

/// Tarjeta con consejo profesional para mejorar las ventas
class ProTipCard extends StatelessWidget {
  const ProTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💡 Consejo PRO",
            style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Subí fotos reales de tus platos. Los productos con fotos venden un 30% más. Usá el botón flotante '+' para agregar items detallados.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
