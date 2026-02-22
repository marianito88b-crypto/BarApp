import 'package:flutter/material.dart';

/// Widget que representa una imagen en la galería
/// 
/// Incluye botón de borrar (esquina superior derecha) y
/// estrella de favorita (esquina superior izquierda).
/// Usa color ámbar para la imagen principal.
class GalleryImageCard extends StatelessWidget {
  final String imageUrl;
  final bool isCoverImage;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const GalleryImageCard({
    super.key,
    required this.imageUrl,
    required this.isCoverImage,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // La Imagen
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white38,
                  ),
                );
              },
            ),
          ),
        ),
        // Botón Borrar (esquina superior derecha)
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // ⭐ Botón Imagen Principal (esquina superior izquierda)
        Positioned(
          left: 0,
          top: 0,
          child: GestureDetector(
            onTap: onToggleFavorite,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCoverImage ? Colors.amber : Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: isCoverImage ? Colors.black : Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
