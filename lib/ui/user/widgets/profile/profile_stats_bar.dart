import 'package:flutter/material.dart';

/// Barra de estadísticas del perfil
/// 
/// Unifica los stats (Reseñas, Puntuación, Antigüedad) en una sola fila
/// con tipografía elegante
class ProfileStatsBar extends StatelessWidget {
  final int reviewCount;
  final double avgRating;
  final String joinDate;
  final Color accentColor;

  const ProfileStatsBar({
    super.key,
    required this.reviewCount,
    required this.avgRating,
    required this.joinDate,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: reviewCount.toString(),
            label: 'Reseñas',
            icon: Icons.rate_review_rounded,
            accentColor: accentColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            value: avgRating.toStringAsFixed(1),
            label: 'Puntuación',
            icon: Icons.star_rounded,
            accentColor: accentColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            value: joinDate,
            label: 'Antigüedad',
            icon: Icons.calendar_month_rounded,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

/// Item individual de estadística
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: accentColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
