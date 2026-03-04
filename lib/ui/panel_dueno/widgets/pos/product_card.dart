import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pos_utils.dart';

/// Widget que representa una tarjeta de producto con soporte para Grid y Lista
class ProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isGrid;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.doc,
    required this.isGrid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};

    final bool controlaStock = data['controlaStock'] ?? false;
    final int stock = PosUtils.safeInt(data['stock']);
    final double precio = PosUtils.safeDouble(data['precio']);

    Widget content = isGrid
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fastfood,
                  size: 40, color: Colors.white24),
              const SizedBox(height: 10),
              Text(
                data['nombre'] ?? 'Sin Nombre',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                "\$${precio.toStringAsFixed(0)}",
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
              if (controlaStock)
                Text(
                  "Stock: $stock",
                  style: TextStyle(
                      color: stock > 0 ? Colors.white54 : Colors.redAccent,
                      fontSize: 10),
                ),
            ],
          )
        : ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.fastfood, color: Colors.white24),
            ),
            title: Text(
              data['nombre'] ?? 'Sin Nombre',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "\$${precio.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.greenAccent),
            ),
            trailing: const Icon(Icons.add_circle,
                color: Colors.orangeAccent, size: 30),
          );

    return Card(
      color: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: isGrid
            ? Padding(padding: const EdgeInsets.all(12), child: content)
            : content,
      ),
    );
  }
}
