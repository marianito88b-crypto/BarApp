import 'package:flutter/material.dart';
import 'dart:ui';

/// Chip de acción moderno con efecto glass
class ActionChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const ActionChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isPrimary
                    ? accentColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPrimary
                      ? accentColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPrimary
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isPrimary ? accentColor : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isPrimary ? accentColor : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
