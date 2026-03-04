import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/services/follow_service.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';

/// Modal con la lista completa de bares seguidos
class FollowedBarsModal extends StatefulWidget {
  final List<String> followingBars;

  const FollowedBarsModal({
    super.key,
    required this.followingBars,
  });

  @override
  State<FollowedBarsModal> createState() => _FollowedBarsModalState();
}

class _FollowedBarsModalState extends State<FollowedBarsModal> {
  late final List<List<String>> _chunks;
  late final List<Stream<QuerySnapshot>> _chunkStreams;

  @override
  void initState() {
    super.initState();
    // Dividir en chunks de 10 para evitar el límite de whereIn
    _chunks = <List<String>>[];
    for (var i = 0; i < widget.followingBars.length; i += 10) {
      _chunks.add(widget.followingBars.sublist(
        i,
        i + 10 > widget.followingBars.length ? widget.followingBars.length : i + 10,
      ));
    }
    _chunkStreams = _chunks.map((chunk) {
      return FirebaseFirestore.instance
          .collection('places')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bares Seguidos (${widget.followingBars.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista de bares
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chunks.length,
                itemBuilder: (context, chunkIndex) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _chunkStreams[chunkIndex],
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final docs = snap.data!.docs;

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final placeId = doc.id;
                          final name = data['name'] ?? 'Bar';

                          // Lógica robusta para imagen
                          String? image;
                          if (data['coverImageUrl'] != null &&
                              data['coverImageUrl'].toString().isNotEmpty) {
                            image = data['coverImageUrl'];
                          } else if ((data['imageUrls'] as List?)?.isNotEmpty ==
                              true) {
                            image = data['imageUrls'][0];
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.orangeAccent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[900],
                                backgroundImage:
                                    image != null ? NetworkImage(image) : null,
                                child: image == null
                                    ? const Icon(
                                        Icons.store,
                                        color: Colors.orangeAccent,
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: const Text(
                                'Recibís notificaciones',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Dejar de seguir',
                                onPressed: () async {
                                  await FollowService.toggleFollow(
                                    placeId: placeId,
                                    isCurrentlyFollowing: true,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Dejaste de seguir a $name'),
                                      backgroundColor: Colors.grey[800],
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlaceDetailScreen(placeId: placeId),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
