import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que representa una tarjeta de producto en el menú del cliente
/// 
/// Diseño premium con gradientes púrpuras, sombras y controles de cantidad.
class ClientProductItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int quantityInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  const ClientProductItem({
    super.key,
    required this.doc,
    required this.quantityInCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    String? imagenUrl = data['fotoUrl'] ?? data['imagen'];
    
    // Check de stock (visual)
    bool controlaStock = data['controlaStock'] ?? false;
    int stock = data['stock'] ?? 0;
    bool sinStock = controlaStock && stock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Imagen
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: imagenUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imagenUrl),
                      fit: BoxFit.cover,
                      colorFilter: sinStock
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                          : null,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (imagenUrl == null)
                  const Center(
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.white24,
                      size: 30,
                    ),
                  ),
                if (sinStock)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text(
                        "AGOTADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (data['descripcion'] != null &&
                      data['descripcion'].toString().isNotEmpty)
                    Text(
                      data['descripcion'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${NumberFormat("#,##0", "es_AR").format(data['precio'] ?? 0)}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      // Controles
                      if (sinStock)
                        const SizedBox() // No mostrar botón si no hay stock
                      else if (quantityInCart == 0)
                        InkWell(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purpleAccent, Colors.deepPurple],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "AGREGAR",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: onRemoveFromCart,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                              ),
                              Text(
                                "$quantityInCart",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.greenAccent,
                                  size: 16,
                                ),
                                onPressed: onAddToCart,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
