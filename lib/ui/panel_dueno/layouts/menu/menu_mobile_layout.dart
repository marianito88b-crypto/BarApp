import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/menu/menu_item_card.dart';
import '../../widgets/menu/full_menu_card.dart';

/// Layout móvil para la pantalla de gestión de menú
class MenuMobileLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> menuStream;
  final Function(String?, Map<String, dynamic>?) onEditProduct;
  final Function(String, String) onDeleteProduct;

  const MenuMobileLayout({
    super.key,
    required this.placeId,
    required this.menuStream,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // CABECERA
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FullMenuCard(placeId: placeId),
                const SizedBox(height: 24),
                const Text(
                  "Productos Individuales",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Tus platos detallados para la app.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // LISTA DE PRODUCTOS
        _buildProductsSliver(),

        // Espacio final para que el botón flotante no tape el último item
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildProductsSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: menuStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 50, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  const Text(
                    "Tu menú está vacío.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        }

        // LISTA MÓVIL
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MenuItemCard(
                  data: docs[i].data() as Map<String, dynamic>,
                  isDesktop: false,
                  onEdit: () => onEditProduct(
                    docs[i].id,
                    docs[i].data() as Map<String, dynamic>,
                  ),
                  onDelete: () => onDeleteProduct(
                    docs[i].id,
                    (docs[i].data() as Map<String, dynamic>)['nombre'] ?? '',
                  ),
                ),
              ),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}
