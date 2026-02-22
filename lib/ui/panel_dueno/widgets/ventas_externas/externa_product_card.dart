import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget que representa una tarjeta de producto para ventas externas
/// 
/// Basado en el diseño del ProductCard del POS pero adaptado para ventas externas
class ExternaProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onTap;

  const ExternaProductCard({
    super.key,
    required this.doc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raw = doc.data() as Map<String, dynamic>;
    final data = {
      ...raw,
      'id': doc.id,
    };

    final double precio = (data['precio'] as num?)?.toDouble() ?? 0.0;

    return Card(
      color: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.fastfood, color: Colors.white24),
        title: Text(
          data['nombre'] ?? 'Sin Nombre',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "\$${precio.toStringAsFixed(0)}",
          style: const TextStyle(color: Colors.greenAccent),
        ),
        trailing: const Icon(
          Icons.add_circle,
          color: Colors.orangeAccent,
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }
}
