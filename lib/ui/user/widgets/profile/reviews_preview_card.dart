import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modals/reviews_modal.dart';

/// Preview de reseñas con puntuación promedio, total, antigüedad y última reseña destacada
class ReviewsPreviewCard extends StatelessWidget {
  final int reviewCount;
  final double avgRating;
  final String joinDate;
  final List<Map<String, dynamic>> reviews;
  final String displayUserName;
  final bool isOwnProfile;
  final Color accentColor;

  const ReviewsPreviewCard({
    super.key,
    required this.reviewCount,
    required this.avgRating,
    required this.joinDate,
    required this.reviews,
    required this.displayUserName,
    required this.isOwnProfile,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener la última reseña destacada (la más reciente con comentario)
    Map<String, dynamic>? featuredReview;
    if (reviews.isNotEmpty) {
      featuredReview = reviews.firstWhere(
        (r) => (r['comment'] as String?)?.isNotEmpty == true,
        orElse: () => reviews.first,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y botón "Ver todas"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reseñas de ${isOwnProfile ? 'tú' : displayUserName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (reviewCount > 0)
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => ReviewsModal(
                        reviews: reviews,
                        displayUserName: displayUserName,
                        isOwnProfile: isOwnProfile,
                      ),
                    );
                  },
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats principales (Reseñas, Puntuación, Antigüedad)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.rate_review_rounded,
                  value: reviewCount.toString(),
                  label: 'Reseñas',
                  accentColor: accentColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _StatChip(
                  icon: Icons.star_rounded,
                  value: avgRating.toStringAsFixed(1),
                  label: 'Puntuación',
                  accentColor: accentColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _StatChip(
                  icon: Icons.calendar_month_rounded,
                  value: joinDate,
                  label: 'Antigüedad',
                  accentColor: accentColor,
                ),
              ),
            ],
          ),

          // Última reseña destacada (si existe)
          if (featuredReview != null && reviewCount > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 12),
            _FeaturedReviewItem(review: featuredReview),
          ],

          // Estado vacío
          if (reviewCount == 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                isOwnProfile
                    ? 'Aún no has escrito reseñas'
                    : 'Sin reseñas',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de estadística individual
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: accentColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Item de reseña destacada en el preview
class _FeaturedReviewItem extends StatefulWidget {
  final Map<String, dynamic> review;

  const _FeaturedReviewItem({required this.review});

  @override
  State<_FeaturedReviewItem> createState() => _FeaturedReviewItemState();
}

class _FeaturedReviewItemState extends State<_FeaturedReviewItem> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isLoading ? 'Cargando...' : _placeName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 14,
                );
              }),
            ),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '"$comment"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
