import 'package:flutter/material.dart';

/// Tarjeta de recompensa de un nivel de BarPoints.
///
/// Muestra el ícono/color del nivel, los puntos requeridos y el porcentaje
/// de descuento. Si [desbloqueado] es `true` muestra el botón "Canjear Cupón";
/// si no, muestra los puntos que le faltan al usuario.
class RewardCard extends StatelessWidget {
  final int puntos;
  final int descuento;
  final bool desbloqueado;
  final int totalPuntos;
  final VoidCallback onCanjear;

  const RewardCard({
    super.key,
    required this.puntos,
    required this.descuento,
    required this.desbloqueado,
    required this.totalPuntos,
    required this.onCanjear,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (puntos) {
      100 => (Icons.military_tech, const Color(0xFFCD7F32)),
      250 => (Icons.military_tech, const Color(0xFFC0C0C0)),
      400 => (Icons.military_tech, const Color(0xFFFFD700)),
      500 => (Icons.diamond, const Color(0xFF4DD0E1)),
      _ => (Icons.star, Colors.orangeAccent),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: desbloqueado
            ? color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: desbloqueado
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            desbloqueado ? icon : Icons.lock_rounded,
            size: 36,
            color: desbloqueado ? color : Colors.white38,
          ),
          const SizedBox(height: 8),
          Text(
            '$puntos pts',
            style: TextStyle(
              color: desbloqueado ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$descuento% descuento',
            style: TextStyle(
              color: desbloqueado ? color : Colors.white38,
              fontSize: 13,
            ),
          ),
          if (desbloqueado) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCanjear,
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Canjear Cupón'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Faltan ${puntos - totalPuntos} pts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
