import 'package:flutter/material.dart';

/// Widget que integra la foto de fondo, avatar y nombre del perfil
/// 
/// Usa gradientes suaves para crear un diseño más integrado y elegante
class ProfileHeaderCard extends StatelessWidget {
  final String? backgroundUrl;
  final String? photoUrl;
  final String displayName;
  final String? instagramHandle;
  final Color accentColor;
  final bool isGuest;
  final VoidCallback? onInstagramTap;

  const ProfileHeaderCard({
    super.key,
    required this.backgroundUrl,
    required this.photoUrl,
    required this.displayName,
    this.instagramHandle,
    required this.accentColor,
    this.isGuest = false,
    this.onInstagramTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- FONDO ---
            backgroundUrl != null && backgroundUrl!.isNotEmpty
                ? Image.network(
                    backgroundUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, s) => _buildDefaultBackground(),
                  )
                : _buildDefaultBackground(),

          // --- GRADIENTE SUPERIOR (Sutil) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- GRADIENTE INFERIOR (Más pronunciado) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- CONTENIDO (Avatar + Nombre + Instagram) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              minimum: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar con borde degradado
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.6),
                          accentColor.withValues(alpha: 0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[900],
                      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Instagram handle (si existe)
                  if (instagramHandle != null && instagramHandle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onInstagramTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@$instagramHandle',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
            Colors.black87,
          ],
        ),
      ),
    );
  }
}
