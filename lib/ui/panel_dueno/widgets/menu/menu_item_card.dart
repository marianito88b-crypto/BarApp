import 'package:flutter/material.dart';
import 'menu_widgets_helpers.dart';

/// Tarjeta de item del menú con layouts optimizados para mobile y desktop
/// 
/// Incluye optimización de RAM mediante cacheWidth para imágenes
class MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemCard({
    super.key,
    required this.data,
    required this.isDesktop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String? fotoUrl = data['fotoUrl'];
    final bool controlaStock = data['controlaStock'] ?? false;
    final int stock = data['stock'] ?? 0;

    bool isCritical = controlaStock && stock < 3 && stock > 0;
    bool isEmpty = controlaStock && stock <= 0;

    Color stockColor = Colors.greenAccent;
    if (stock < 10) stockColor = Colors.orangeAccent;
    if (stock < 3) stockColor = Colors.redAccent;

    if (isDesktop) {
      return _buildDesktopLayout(
        fotoUrl: fotoUrl,
        controlaStock: controlaStock,
        stock: stock,
        stockColor: stockColor,
        isCritical: isCritical,
        isEmpty: isEmpty,
      );
    } else {
      return _buildMobileLayout(
        fotoUrl: fotoUrl,
        controlaStock: controlaStock,
        stock: stock,
        stockColor: stockColor,
        isEmpty: isEmpty,
      );
    }
  }

  /// Construye la imagen optimizada con cacheWidth para reducir uso de RAM
  Widget _buildOptimizedImage({
    required double width,
    required double height,
    required bool isCircle,
    required String? fotoUrl,
    required bool isEmpty,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(isCircle ? 8 : 12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircle ? 8 : 12),
        child: fotoUrl != null
            ? Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                // 🔥 EL TRUCO MAESTRO: Redimensiona en RAM según el dispositivo
                cacheWidth: isDesktop ? 500 : 150,
                // Filtro de saturación si no hay stock
                color: isEmpty ? Colors.grey : null,
                colorBlendMode: isEmpty ? BlendMode.saturation : null,
                // 🪄 FADE-IN SUAVE
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.white10),
              )
            : const Icon(Icons.fastfood, color: Colors.white24),
      ),
    );
  }

  /// Layout para desktop (Grid)
  Widget _buildDesktopLayout({
    required String? fotoUrl,
    required bool controlaStock,
    required int stock,
    required Color stockColor,
    required bool isCritical,
    required bool isEmpty,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isCritical || isEmpty)
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // IMAGEN OPTIMIZADA DESKTOP
                Positioned(
                  child: _buildOptimizedImage(
                    width: double.infinity,
                    height: double.infinity,
                    isCircle: false,
                    fotoUrl: fotoUrl,
                    isEmpty: isEmpty,
                  ),
                ),

                if (isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "AGOTADO",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                // BOTONES
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAction(
                    icon: Icons.delete,
                    color: Colors.redAccent,
                    onTap: onDelete,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CategoryBadge(
                    label: data['categoria'] ?? 'General',
                  ),
                ),

                if (controlaStock)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: StockBadge(
                      stock: stock,
                      color: stockColor,
                      isCritical: isCritical,
                      isEmpty: isEmpty,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nombre'] ?? 'Plato',
                        style: TextStyle(
                          color: isEmpty ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${(data['precio'] as num?)?.toStringAsFixed(0) ?? '0'}",
                        style: TextStyle(
                          color: isEmpty ? Colors.white38 : Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        "Editar / Reponer",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para móvil (Lista)
  Widget _buildMobileLayout({
    required String? fotoUrl,
    required bool controlaStock,
    required int stock,
    required Color stockColor,
    required bool isEmpty,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        onTap: onEdit,
        leading: Stack(
          children: [
            _buildOptimizedImage(
              width: 60,
              height: 60,
              isCircle: true,
              fotoUrl: fotoUrl,
              isEmpty: isEmpty,
            ),
            if (isEmpty)
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.block,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
          ],
        ),
        title: Text(
          data['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            color: isEmpty ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  data['categoria'] ?? 'General',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
                if (controlaStock) ...[
                  const SizedBox(width: 8),
                  StockBadgeSmall(
                    stock: stock,
                    color: stockColor,
                    isEmpty: isEmpty,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${(data['precio'] as num?)?.toStringAsFixed(0) ?? '0'}",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.edit, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
