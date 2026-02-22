import 'package:flutter/material.dart';

/// Widget que representa un producto en la lista de ventas externas
/// 
/// Muestra el nombre y precio del producto con un botón para agregarlo al carrito.
class ExternaProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ExternaProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          product['nombre'] ?? 'Sin nombre',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "\$${product['precio']}",
          style: const TextStyle(color: Colors.greenAccent),
        ),
        trailing: const Icon(
          Icons.add_circle,
          color: Colors.orangeAccent,
        ),
        onTap: onTap,
      ),
    );
  }
}
