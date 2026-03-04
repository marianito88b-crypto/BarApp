import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'client_ratings_modal.dart';

/// Tarjeta resumen de reputación del cliente (Ruta B).
///
/// Lee el campo reputacion_cliente del perfil del usuario.
/// Al hacer tap, abre ClientRatingsModal con el detalle completo.
///
/// Intenta leer de 'usuarios' primero y luego de 'users'.
class ClientReputationCard extends StatefulWidget {
  final String? userId;

  const ClientReputationCard({
    super.key,
    this.userId,
  });

  @override
  State<ClientReputationCard> createState() => _ClientReputationCardState();
}

class _ClientReputationCardState extends State<ClientReputationCard> {
  late final String? _currentUserId;
  late final Future<String>? _collectionFuture;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _collectionFuture = _currentUserId != null
        ? _resolveCollection(_currentUserId)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const SizedBox.shrink();

    // Intentar con 'usuarios'; si vacío usará 'users' via FutureBuilder
    return FutureBuilder<String>(
      future: _collectionFuture,
      builder: (context, futureSnap) {
        if (!futureSnap.hasData) return const SizedBox.shrink();
        final collection = futureSnap.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .doc(_currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final userData =
                snapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) return const SizedBox.shrink();

            final reputacionData =
                userData['reputacion_cliente'] as Map<String, dynamic>?;
            if (reputacionData == null) return const SizedBox.shrink();

            final promedioEstrellas =
                (reputacionData['promedioEstrellas'] as num?)?.toDouble() ??
                    0.0;
            final totalCalificaciones =
                (reputacionData['totalCalificaciones'] as num?)?.toInt() ?? 0;

            if (totalCalificaciones == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => ClientRatingsModal.show(context, _currentUserId),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.18),
                        Colors.blueAccent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mi Reputación",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(
                                  i < promedioEstrellas.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.blueAccent,
                                  size: 18,
                                )),
                                const SizedBox(width: 8),
                                Text(
                                  promedioEstrellas.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  "$totalCalificaciones ${totalCalificaciones == 1 ? 'calificación' : 'calificaciones'} de bares",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white54,
                                  size: 11,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _resolveCollection(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    return snap.exists ? 'usuarios' : 'users';
  }
}
