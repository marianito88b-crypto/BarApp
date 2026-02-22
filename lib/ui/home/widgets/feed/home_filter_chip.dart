import 'package:flutter/material.dart';

/// Chip de filtro visualmente mejorado para el feed
/// 
/// Usado en la barra de filtros del feed (Populares, Cercanía, Abierto, etc.)
class HomeFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const HomeFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF7F50);
    const inactiveColor = Color(0xFF2C2C2C);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // 🔥 Padding reducido para que entren bien en la fila
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(18), // Un poco más redondeado
          border: isActive
              ? Border.all(color: activeColor)
              : Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isActive ? Colors.black : Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 12, // Letra un pelín más chica para optimizar espacio
              ),
            ),
          ],
        ),
      ),
    );
  }
}
