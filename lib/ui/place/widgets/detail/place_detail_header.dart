import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barapp/services/follow_service.dart';

/// Header modernizado del detalle de lugar con efecto Glass
/// 
/// Implementa un SliverAppBar con BackdropFilter y botón de favorito
class PlaceDetailHeader extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String? coverImageUrl;
  final Color accentColor;

  const PlaceDetailHeader({
    super.key,
    required this.placeId,
    required this.placeName,
    this.coverImageUrl,
    required this.accentColor,
  });

  @override
  State<PlaceDetailHeader> createState() => _PlaceDetailHeaderState();
}

class _PlaceDetailHeaderState extends State<PlaceDetailHeader> {
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: widget.accentColor,
      actions: [
        // Botón de favorito con StreamBuilder
        StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, userSnap) {
            // Verificar si lo sigue
            final userData = userSnap.data?.data() as Map<String, dynamic>?;
            final List following = userData?['followingBars'] ?? [];
            final bool isFollowing = following.contains(widget.placeId);

            return Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: IconButton(
                icon: Icon(
                  isFollowing ? Icons.favorite : Icons.favorite_border,
                  color: isFollowing ? Colors.redAccent : Colors.white,
                ),
                onPressed: () async {
                  await FollowService.toggleFollow(
                    placeId: widget.placeId,
                    isCurrentlyFollowing: isFollowing,
                  );
                },
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.placeName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 10),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            widget.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: widget.accentColor),
                    errorWidget: (context, url, error) => Container(
                      color: widget.accentColor.withValues(alpha: 0.5),
                      child: const Icon(Icons.error, color: Colors.white24),
                    ),
                  )
                : Container(
                    color: widget.accentColor.withValues(alpha: 0.5),
                    child: const Icon(Icons.store, size: 80, color: Colors.white24),
                  ),

            // 🔥 EFECTO GLASS: BackdropFilter con color naranja oscuro semitransparente
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.orange.shade900.withValues(alpha: 0.4),
                        Colors.orange.shade800.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Gradiente inferior para legibilidad del título
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
