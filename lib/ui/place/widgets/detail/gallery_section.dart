import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Sección de galería de fotos del lugar
class GallerySection extends StatelessWidget {
  final List<String> gallery;
  final void Function(String imageUrl, String nombrePlato) onImageTap;

  const GallerySection({
    super.key,
    required this.gallery,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Galería",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gallery.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => onImageTap(gallery[index], "Galería"),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: gallery[index],
                  width: 140,
                  fit: BoxFit.cover,
                  memCacheHeight: 300,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
