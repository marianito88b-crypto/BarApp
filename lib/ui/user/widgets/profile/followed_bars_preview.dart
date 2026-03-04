import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';
import 'modals/followed_bars_modal.dart';

/// Preview de bares seguidos con carrusel horizontal
/// 
/// Muestra un pequeño carrusel de logos y un botón "Ver todos"
class FollowedBarsPreview extends StatefulWidget {
  const FollowedBarsPreview({super.key});

  @override
  State<FollowedBarsPreview> createState() => _FollowedBarsPreviewState();
}

class _FollowedBarsPreviewState extends State<FollowedBarsPreview> {
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _placesStream;
  List<String>? _cachedPreviewList;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .snapshots();
    }
  }

  Stream<QuerySnapshot> _getPlacesStream(List<String> previewList) {
    if (_cachedPreviewList == null || !_listEquals(_cachedPreviewList!, previewList)) {
      _cachedPreviewList = List.from(previewList);
      _placesStream = FirebaseFirestore.instance
          .collection('places')
          .where(FieldPath.documentId, whereIn: previewList)
          .snapshots();
    }
    return _placesStream!;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();

        final data = userSnap.data!.data() as Map<String, dynamic>?;
        final List<String> followingBars =
            List<String>.from(data?['followingBars'] ?? []);

        if (followingBars.isEmpty) {
          return const SizedBox.shrink();
        }

        // Tomamos solo los primeros 5 para el preview
        final previewList = followingBars.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SEGUÍS ${followingBars.length} BARES',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (followingBars.length > 5)
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => FollowedBarsModal(
                            followingBars: followingBars,
                          ),
                        );
                      },
                      child: const Text(
                        'Ver todos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _getPlacesStream(previewList),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: docs.length + (followingBars.length > 5 ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      // Botón "Ver todos" al final si hay más de 5
                      if (index == docs.length && followingBars.length > 5) {
                        return _ViewAllButton(
                          totalCount: followingBars.length,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => FollowedBarsModal(
                                followingBars: followingBars,
                              ),
                            );
                          },
                        );
                      }

                      final doc = docs[index];
                      final placeData = doc.data() as Map<String, dynamic>;
                      final placeId = doc.id;
                      final name = placeData['name'] ?? 'Bar';

                      // Lógica robusta para imagen
                      String? image;
                      if (placeData['coverImageUrl'] != null &&
                          placeData['coverImageUrl'].toString().isNotEmpty) {
                        image = placeData['coverImageUrl'];
                      } else if ((placeData['imageUrls'] as List?)?.isNotEmpty ==
                          true) {
                        image = placeData['imageUrls'][0];
                      }

                      return _BarLogoCard(
                        placeId: placeId,
                        name: name,
                        imageUrl: image,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(placeId: placeId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Tarjeta individual del logo del bar en el carrusel
class _BarLogoCard extends StatelessWidget {
  final String placeId;
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _BarLogoCard({
    required this.placeId,
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(
                      Icons.store,
                      color: Colors.orangeAccent,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón "Ver todos" en el carrusel
class _ViewAllButton extends StatelessWidget {
  final int totalCount;
  final VoidCallback onTap;

  const _ViewAllButton({
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '+${totalCount - 5}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Ver todos',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
