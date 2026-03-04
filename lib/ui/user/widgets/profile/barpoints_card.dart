import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barapp/ui/user/bar_points_detail_screen.dart';

/// Tarjeta destacada de BarPoints con efecto glass y sombreado iluminado.
/// Resalta los puntos acumulados sobre el resto de menús.
class BarPointsCard extends StatefulWidget {
  final String? userId;

  const BarPointsCard({
    super.key,
    this.userId,
  });

  @override
  State<BarPointsCard> createState() => _BarPointsCardState();
}

class _BarPointsCardState extends State<BarPointsCard> {
  late final Future<String?> _collectionFuture;

  @override
  void initState() {
    super.initState();
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _collectionFuture =
        uid != null ? _resolveCollection(uid) : Future.value(null);
  }

  /// Resuelve en qué colección está el usuario (usuarios o users).
  Future<String?> _resolveCollection(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    return snap.exists ? 'usuarios' : 'users';
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<String?>(
      future: _collectionFuture,
      builder: (context, colSnap) {
        final collection = colSnap.data;
        if (collection == null) return const SizedBox.shrink();

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            final userData =
                userSnap.data?.data() as Map<String, dynamic>?;
            final totalPuntos =
                (userData?['barPoints'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarPointsDetailScreen(userId: uid),
                    ),
                  ),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withValues(alpha: 0.25),
                      Colors.orangeAccent.withValues(alpha: 0.08),
                      Colors.orangeAccent.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Sombra iluminada exterior (glow)
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                    // Sombra sutil interna
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.orangeAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "BarPoints",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$totalPuntos puntos",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: Colors.orangeAccent.withValues(alpha: 0.9),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Acumulá y canjeá descuentos",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.orangeAccent,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
          },
        );
      },
    );
  }
}
