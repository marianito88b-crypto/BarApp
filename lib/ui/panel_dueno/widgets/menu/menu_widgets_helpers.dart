import 'package:flutter/material.dart';

/// Badge circular para acciones (editar, eliminar, etc.)
class CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CircleAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

/// Badge para mostrar la categoría del producto
class CategoryBadge extends StatelessWidget {
  final String label;

  const CategoryBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Badge para mostrar el stock del producto (versión grande para desktop)
class StockBadge extends StatelessWidget {
  final int stock;
  final Color color;
  final bool isCritical;
  final bool isEmpty;

  const StockBadge({
    super.key,
    required this.stock,
    required this.color,
    required this.isCritical,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCritical)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.warning, size: 12, color: Colors.redAccent),
            ),
          Text(
            isEmpty ? "AGOTADO" : "$stock u.",
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge pequeño para mostrar el stock (versión compacta para móvil)
class StockBadgeSmall extends StatelessWidget {
  final int stock;
  final Color color;
  final bool isEmpty;

  const StockBadgeSmall({
    super.key,
    required this.stock,
    required this.color,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isEmpty ? "SIN STOCK" : "Stock: $stock",
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
