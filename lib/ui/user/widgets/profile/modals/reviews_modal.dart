import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modal con el historial completo de reseñas
class ReviewsModal extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final String displayUserName;
  final bool isOwnProfile;

  const ReviewsModal({
    super.key,
    required this.reviews,
    required this.displayUserName,
    required this.isOwnProfile,
  });

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
                    'Reseñas de ${isOwnProfile ? 'tú' : displayUserName}',
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

            // Lista de reseñas
            Expanded(
              child: reviews.isEmpty
                  ? Center(
                      child: Text(
                        isOwnProfile
                            ? 'Aún no has escrito reseñas'
                            : 'Sin reseñas',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _ReviewItem(review: reviews[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item individual de reseña en el modal
class _ReviewItem extends StatefulWidget {
  final Map<String, dynamic> review;

  const _ReviewItem({required this.review});

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  String _placeName = 'Cargando...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaceName();
  }

  Future<void> _loadPlaceName() async {
    final existingName = widget.review['placeName'] as String?;
    if (existingName != null && existingName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _placeName = existingName;
          _isLoading = false;
        });
      }
      return;
    }

    final placeId = widget.review['placeId'] as String?;
    if (placeId == null) {
      if (mounted) {
        setState(() {
          _placeName = 'Lugar desconocido';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final placeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();

      if (placeDoc.exists) {
        _placeName = placeDoc.data()?['name'] as String? ?? 'Lugar (Error)';
      } else {
        _placeName = 'Lugar (eliminado)';
      }
    } catch (e) {
      _placeName = 'Lugar (Error)';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = (widget.review['rating'] as num?)?.toInt() ?? 0;
    final comment = widget.review['comment'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoading ? 'Cargando...' : _placeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"$comment"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
