import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/ui/user/user_profile_screen.dart';
import 'package:barapp/ui/chat/chat_screen.dart';
import '../delivery/client_rating_dialog.dart';

/// Dashboard del bar: muestra lo que los CLIENTES dicen del BAR.
///
/// RUTA A: Lee de places/{placeId}/ratings_recibidas
/// Campos: estrellas, etiquetas, comentarios, clienteNombre, clienteId, timestamp.
/// Avatar y displayName se obtienen del documento del usuario (usuarios/users).
class RatingsHistoryCard extends StatefulWidget {
  final String placeId;

  const RatingsHistoryCard({
    super.key,
    required this.placeId,
  });

  @override
  State<RatingsHistoryCard> createState() => _RatingsHistoryCardState();
}

class _RatingsHistoryCardState extends State<RatingsHistoryCard> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('ratings_recibidas')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Text(
                "Aún no hay calificaciones de clientes",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        double sumaEstrellas = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          sumaEstrellas += (data['estrellas'] as num?)?.toDouble() ?? 0;
        }
        final promedio = sumaEstrellas / docs.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lo que dicen tus clientes",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orangeAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          promedio.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          " (${docs.length})",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final clienteNombre =
                    data['clienteNombre'] as String? ?? 'Cliente';
                final userId = data['clienteId'] as String? ?? '';
                final orderId = data['orderId'] as String? ?? doc.id;
                final estrellas = (data['estrellas'] as num?)?.toInt() ?? 0;
                final etiquetas = List<String>.from(
                  data['etiquetas'] as List? ?? [],
                );
                final comentarios = data['comentarios'] as String?;
                final timestamp = data['timestamp'] as Timestamp?;

                return _RatingItem(
                  clienteNombre: clienteNombre,
                  userId: userId,
                  orderId: orderId,
                  placeId: widget.placeId,
                  estrellas: estrellas,
                  etiquetas: etiquetas,
                  comentarios: comentarios,
                  fecha: timestamp?.toDate(),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RatingItem extends StatelessWidget {
  final String clienteNombre;
  final String userId;
  final String orderId;
  final String placeId;
  final int estrellas;
  final List<String> etiquetas;
  final String? comentarios;
  final DateTime? fecha;

  const _RatingItem({
    required this.clienteNombre,
    required this.userId,
    required this.orderId,
    required this.placeId,
    required this.estrellas,
    required this.etiquetas,
    required this.comentarios,
    required this.fecha,
  });

  Future<Map<String, dynamic>> _loadUserData() async {
    if (userId.isEmpty) return {};
    final db = FirebaseFirestore.instance;
    for (final col in ['usuarios', 'users']) {
      final snap = await db.collection(col).doc(userId).get();
      if (snap.exists) {
        final d = snap.data() ?? {};
        return {
          'displayName': d['displayName'] as String? ?? d['nombre'] as String? ?? clienteNombre,
          'imageUrl': d['imageUrl'] as String? ?? '',
          'collection': col,
        };
      }
    }
    return {'displayName': clienteNombre, 'imageUrl': '', 'collection': ''};
  }

  void _onAvatarTap(BuildContext context) async {
    if (userId.isEmpty) return;
    final userData = await _loadUserData();
    final displayName = userData['displayName'] as String? ?? clienteNombre;
    final imageUrl = userData['imageUrl'] as String? ?? '';

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              externalUserId: userId,
                              externalUserName: displayName,
                              externalUserPhotoUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person, color: Colors.orangeAccent),
                      label: const Text(
                        "Ver perfil",
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: userId,
                              otherDisplayName: displayName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                      label: const Text(
                        "Enviar mensaje",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _loadUserData(),
            builder: (context, snap) {
              final imageUrl = snap.data?['imageUrl'] as String? ?? '';
              final displayName = snap.data?['displayName'] as String? ?? clienteNombre;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: userId.isNotEmpty ? () => _onAvatarTap(context) : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Tooltip(
                      message: userId.isNotEmpty
                          ? "Ver perfil o enviar mensaje"
                          : "Cliente sin cuenta",
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.orangeAccent,
                                size: 22,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (fecha != null)
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(fecha!),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.orangeAccent,
                      size: 16,
                    ),
                  ),
                ],
              ),
                  if (userId.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: "Calificar a este cliente",
                      child: IconButton(
                        icon: const Icon(
                          Icons.rate_review_rounded,
                          size: 18,
                          color: Colors.orangeAccent,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ClientRatingDialog(
                              userId: userId,
                              orderId: orderId,
                              placeId: placeId,
                              clienteNombre: displayName,
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (etiquetas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: etiquetas.map((tag) => _Tag(label: tag)).toList(),
            ),
          ],
          if (comentarios != null && comentarios!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comentarios!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Colors.greenAccent, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
