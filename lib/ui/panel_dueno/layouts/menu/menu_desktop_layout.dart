import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/menu/menu_item_card.dart';
import '../../widgets/menu/full_menu_card.dart';
import '../../widgets/menu/pro_tip_card.dart';

/// Layout desktop para la pantalla de gestión de menú
class MenuDesktopLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> menuStream;
  final Function(String?, Map<String, dynamic>?) onEditProduct;
  final Function(String, String) onDeleteProduct;

  const MenuDesktopLayout({
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Gestión de Menú",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FullMenuCard(placeId: placeId),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      flex: 3,
                      child: ProTipCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),
                const Text(
                  "Catálogo de Productos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // GRID DE PRODUCTOS
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
              margin: const EdgeInsets.symmetric(horizontal: 24),
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

        // GRID DESKTOP
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => MenuItemCard(
                data: docs[i].data() as Map<String, dynamic>,
                isDesktop: true,
                onEdit: () => onEditProduct(
                  docs[i].id,
                  docs[i].data() as Map<String, dynamic>,
                ),
                onDelete: () => onDeleteProduct(
                  docs[i].id,
                  (docs[i].data() as Map<String, dynamic>)['nombre'] ?? '',
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
