import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra la barra flotante verde del carrito en la parte inferior
/// 
/// Diseño premium con sombras y gradientes. Muestra el total y cantidad de items.
class CartBottomBar extends StatelessWidget {
  final Map<String, Map<String, dynamic>> cart;
  final VoidCallback onTap;

  const CartBottomBar({
    super.key,
    required this.cart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    int itemsCount = 0;
    cart.forEach((key, value) {
      total += (value['precio'] * value['cantidad']);
      itemsCount += (value['cantidad'] as int);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$itemsCount items",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                "VER PEDIDO",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "\$${NumberFormat("#,##0", "es_AR").format(total)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
