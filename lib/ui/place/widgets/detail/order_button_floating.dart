import 'package:flutter/material.dart';
import 'dart:ui';

/// Botón flotante destacado para "Pedir Online" con efecto glass
class OrderButtonFloating extends StatelessWidget {
  final bool deliveryDisponible;
  final bool aceptaPedidos;
  final bool menuVisible;
  final bool isGuest;
  final VoidCallback onPressed;
  final VoidCallback? onGuestPressed;

  const OrderButtonFloating({
    super.key,
    required this.deliveryDisponible,
    required this.aceptaPedidos,
    required this.menuVisible,
    required this.isGuest,
    required this.onPressed,
    this.onGuestPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!aceptaPedidos || !menuVisible) {
      return const SizedBox.shrink();
    }

    final accentColor = deliveryDisponible ? Colors.purpleAccent : Colors.orangeAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGuest && onGuestPressed != null ? onGuestPressed : onPressed,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      deliveryDisponible
                          ? Icons.delivery_dining
                          : Icons.shopping_bag_outlined,
                      size: 26,
                      color: deliveryDisponible ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        deliveryDisponible
                            ? "HACER PEDIDO ONLINE / DELIVERY"
                            : "PEDIR PARA RETIRAR",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: deliveryDisponible ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
