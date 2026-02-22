import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Sección de opiniones/reviews del lugar
class ReviewsSection extends StatelessWidget {
  final String placeId;
  final Color accentColor;

  const ReviewsSection({
    super.key,
    required this.placeId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Opiniones recientes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .collection('ratings')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final reviews = snapshot.data?.docs ?? [];
            if (reviews.isEmpty) {
              return const Text(
                'Sé el primero en opinar.',
                style: TextStyle(color: Colors.white70),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) => ReviewItem(
                review: reviews[index].data() as Map<String, dynamic>,
                accentColor: accentColor,
              ),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

/// Widget individual de review
class ReviewItem extends StatelessWidget {
  final Map<String, dynamic> review;
  final Color accentColor;

  const ReviewItem({
    super.key,
    required this.review,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment'] as String? ?? '';
    final userName = review['userName'] as String? ?? 'Usuario';
    final userPhoto = review['userAvatarUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.3),
                backgroundImage: (userPhoto.isNotEmpty)
                    ? NetworkImage(userPhoto)
                    : null,
                child: userPhoto.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Nombre y Estrellas
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.normal,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
