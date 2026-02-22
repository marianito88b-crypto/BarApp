import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal completo del menú del cliente
/// 
/// Muestra el menú agrupado por categorías con Slivers y pre-carga del Stream
class ClientMenuModal {
  /// Muestra el modal del menú con agrupamiento por categorías
  static void show(
    BuildContext context, {
    required String placeId,
    required Stream<QuerySnapshot> menuStream,
    required List<String> categoryOrder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Nuestra Carta",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: menuStream, // 🚀 USA LA PRE-CARGA (Carga instantánea)
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "El menú se está actualizando...",
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      // 1. AGRUPAMIENTO INTELIGENTE
                      Map<String, List<QueryDocumentSnapshot>> groupedMenu = {};
                      for (var doc in docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        String cat = data['categoria'] ?? 'Varios';
                        if (cat.isNotEmpty) {
                          cat = cat[0].toUpperCase() + cat.substring(1);
                        }
                        if (!groupedMenu.containsKey(cat)) {
                          groupedMenu[cat] = [];
                        }
                        groupedMenu[cat]!.add(doc);
                      }

                      // 2. ORDENAMIENTO DE CATEGORÍAS
                      List<String> sortedCats = groupedMenu.keys.toList();
                      sortedCats.sort((a, b) {
                        int indexA = categoryOrder.indexOf(a);
                        int indexB = categoryOrder.indexOf(b);
                        if (indexA != -1 && indexB != -1) {
                          return indexA.compareTo(indexB);
                        }
                        if (indexA != -1) return -1;
                        if (indexB != -1) return 1;
                        return a.compareTo(b);
                      });

                      // 3. CONSTRUCCIÓN DE LA UI (SLIVERS)
                      return CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _FullMenuButton(placeId: placeId),
                          ),

                          ...sortedCats.map((category) {
                            final products = groupedMenu[category]!;
                            return SliverMainAxisGroup(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: _CategoryHeader(title: category),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, index) => _ProductPreviewItem(
                                      doc: products[index],
                                      onImageTap: (imageUrl, nombre) =>
                                          _showDishImage(context, imageUrl, nombre),
                                    ),
                                    childCount: products.length,
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 20),
                                ),
                              ],
                            );
                          }),
                          const SliverToBoxAdapter(child: SizedBox(height: 50)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra el diálogo de imagen de plato individual
  static void _showDishImage(
    BuildContext context,
    String imageUrl,
    String nombrePlato,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // IMAGEN CON ZOOM
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),

            // TÍTULO DEL PLATO (Abajo)
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nombrePlato,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // BOTÓN CERRAR (Arriba derecha)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón para ver la carta completa (PDF o imagen)
class _FullMenuButton extends StatelessWidget {
  final String placeId;

  const _FullMenuButton({required this.placeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String? url = data['fullMenuUrl'];
        final String type = data['fullMenuType'] ?? 'image';

        if (url == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.orangeAccent.withValues(alpha: 0.5),
                ),
              ),
            ),
            icon: Icon(type == 'pdf' ? Icons.picture_as_pdf : Icons.image),
            label: const Text(
              "VER CARTA ORIGINAL (FOTO/PDF)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _openFullMenu(context, url, type),
          ),
        );
      },
    );
  }

  /// Abre la carta completa (PDF o imagen)
  Future<void> _openFullMenu(
    BuildContext context,
    String url,
    String type,
  ) async {
    if (type == 'pdf') {
      // PDF: Delegamos al sistema
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // IMAGEN: Usamos visor con Zoom y Panning
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Cerrar",
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (ctx, anim1, anim2) {
          return SafeArea(
            child: Stack(
              children: [
                // EL VISOR
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    clipBehavior: Clip.none,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // BOTÓN CERRAR FLOTANTE
                Positioned(
                  top: 20,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),

                // INDICACIÓN
                const Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Pellizca para hacer Zoom",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}

/// Header de categoría con estilo premium
class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 15),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent.withValues(alpha: 0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ítem de producto en el menú
class _ProductPreviewItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final void Function(String imageUrl, String nombre) onImageTap;

  const _ProductPreviewItem({
    required this.doc,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    String? fotoUrl = data['fotoUrl'] ?? data['imagen'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: fotoUrl != null
              ? () => onImageTap(fotoUrl, data['nombre'] ?? '')
              : null,
          child: Row(
            children: [
              // FOTO OPTIMIZADA
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.white10,
                  child: fotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fotoUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 250,
                          memCacheWidth: 250,
                          maxWidthDiskCache: 400,
                          placeholder: (context, url) => const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white12,
                              size: 20,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Colors.white12,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: Colors.white24,
                          size: 30,
                        ),
                ),
              ),

              // INFO
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (data['descripcion'] != null &&
                          data['descripcion'].toString().isNotEmpty)
                        Text(
                          data['descripcion'],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "\$${NumberFormat("#,##0", "es_AR").format(data['precio'] ?? 0)}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (fotoUrl != null) ...[
                            const Spacer(),
                            const Icon(
                              Icons.zoom_in,
                              color: Colors.white38,
                              size: 16,
                            ),
                            const Text(
                              " Ver",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
