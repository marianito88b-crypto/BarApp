import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Sección de información del lugar
/// 
/// Muestra puntuación, distancia, descripción y contador de seguidores
class VenueInfoSection extends StatelessWidget {
  final String placeId;
  final String? description;
  final double? distanceInMeters;
  final String Function(double) formatDistance;
  final Map<String, dynamic> placeData;
  final Future<void> Function(String) onLaunchUrl;

  const VenueInfoSection({
    super.key,
    required this.placeId,
    this.description,
    this.distanceInMeters,
    required this.formatDistance,
    required this.placeData,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. INFO BÁSICA (Puntuación y Distancia)
        Row(
          children: [
            // Puntuación
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .doc(placeId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!.data();
                final avg = (data?['ratingAvg'] as num?)?.toDouble() ?? 0.0;
                final count = (data?['ratingCount'] as num?)?.toInt() ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        count == 0 ? "Nuevo" : "${avg.toStringAsFixed(1)} ($count)",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            // Distancia
            if (distanceInMeters != null && distanceInMeters!.isFinite)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      formatDistance(distanceInMeters!),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 15),

        // 2. CONTADOR DE SEGUIDORES (con iconos de redes sociales a la derecha)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFollowersSection(placeId),
            ),
            // Iconos de redes sociales a la derecha de seguidores (debajo de la distancia)
            const SizedBox(width: 12),
            _buildSocialIcons(),
          ],
        ),

        const SizedBox(height: 20),

        // 3. DESCRIPCIÓN DEL LUGAR
        if (description != null && description!.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sobre este lugar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Construye la sección de seguidores con contador y avatares
  Widget _buildFollowersSection(String placeId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CONTADOR
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.data()?['followersCount'] ?? 0;
            return Text(
              "❤️ $count seguidores",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // AVATARES (LIMITADOS)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .collection('followers')
              .orderBy('followedAt', descending: true)
              .limit(8)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Row(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final img = data['imageUrl'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    backgroundImage:
                        img != null && img.isNotEmpty ? NetworkImage(img) : null,
                    child: img == null
                        ? const Icon(Icons.person, size: 16, color: Colors.white54)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Construye los iconos de redes sociales (WhatsApp e Instagram)
  Widget _buildSocialIcons() {
    final String whatsapp = placeData['whatsapp'] ?? '';
    final String instagram = placeData['instagram'] ?? '';

    // Si no hay ninguna red social configurada, no mostrar nada
    if (whatsapp.isEmpty && instagram.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // WhatsApp
        _SocialIconButton(
          icon: FontAwesomeIcons.whatsapp,
          color: const Color(0xFF25D366),
          hasValue: whatsapp.isNotEmpty,
          onTap: whatsapp.isNotEmpty
              ? () async {
                  final cleanNum = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
                  await onLaunchUrl("https://wa.me/$cleanNum");
                }
              : () {
                  // No necesitamos mostrar snackbar aquí porque el icono ya indica que no está disponible
                },
        ),
        if (whatsapp.isNotEmpty || instagram.isNotEmpty) const SizedBox(width: 8),
        // Instagram
        _SocialIconButton(
          icon: FontAwesomeIcons.instagram,
          color: const Color(0xFFE1306C),
          hasValue: instagram.isNotEmpty,
          onTap: instagram.isNotEmpty
              ? () async {
                  final user = instagram.replaceAll('@', '').trim();
                  await onLaunchUrl("https://instagram.com/$user");
                }
              : () {
                  // No necesitamos mostrar snackbar aquí porque el icono ya indica que no está disponible
                },
        ),
      ],
    );
  }

}

/// Botón individual de red social con efecto glass (versión pequeña para chips)
class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool hasValue;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasValue ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: hasValue ? 0.4 : 0.2),
                  width: 1.5,
                ),
              ),
              child: FaIcon(
                icon,
                color: color.withValues(alpha: hasValue ? 1.0 : 0.5),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
