import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Tarjeta de evento para la vista de administración
class AdminEventCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminEventCard({
    super.key,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isShow = data['type'] == 'show';
    final color = isShow ? Colors.amber : Colors.greenAccent;
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final imageUrl = data['imageUrl'];
    final isPast = date.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.shade900 : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        image: imageUrl != null && imageUrl.toString().isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: isPast ? 0.8 : 0.6),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          if (isPast)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "FINALIZADO",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isShow
                                ? FontAwesomeIcons.music
                                : Icons.local_offer,
                            color: Colors.black,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isShow ? "SHOW" : "PROMO",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        DateFormat("dd/MM • HH:mm").format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['title'] ?? 'Sin título',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
