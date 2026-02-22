import 'package:flutter/material.dart';

/// Widget que muestra una opción seleccionable con efecto ripple
/// 
/// Usado para seleccionar método de entrega (Retiro/Delivery) o método de pago.
/// Diseño premium con animaciones y efectos visuales.
class DeliveryOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const DeliveryOptionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos Material transparente para que el InkWell se dibuje encima del color del Container
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.greenAccent : Colors.white10,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent, // Importante para el efecto ripple
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.white54,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
