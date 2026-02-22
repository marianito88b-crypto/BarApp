import 'package:flutter/material.dart';
import 'dart:ui';

/// Botón de vidrio con efecto blur y borde de color
/// 
/// Usado en el header del feed para los botones de acciones premium
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color color; // El color define el Borde y el Splash
  final String tooltip;
  final VoidCallback onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            // El efecto al tocar sigue siendo del color del botón (naranja, azul, etc)
            splashColor: color.withValues(alpha: 0.3),
            highlightColor: color.withValues(alpha: 0.1),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // Fondo muy sutil
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                // 🔥 EL BORDE LLEVA EL COLOR (Un poco más visible ahora)
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              // 🔥 EL ÍCONO ES BLANCO PURO
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
