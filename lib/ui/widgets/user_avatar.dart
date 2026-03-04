import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar circular de usuario con fallback a imagen local.
///
/// Usa [imageUrl] si está disponible; de lo contrario muestra
/// `assets/images/usuario.png` para evitar slots vacíos ("fantasmas").
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1A1A1A),
      backgroundImage: hasUrl
          ? CachedNetworkImageProvider(imageUrl!)
          : const AssetImage('assets/images/usuario.png') as ImageProvider,
    );
  }
}
