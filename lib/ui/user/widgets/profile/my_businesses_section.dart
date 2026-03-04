import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/panel_dueno/panel_dueno_screen.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';

/// Sección modernizada de negocios del usuario
/// 
/// Usa tarjetas redondeadas con bordes neón sutiles
class MyBusinessesSection extends StatefulWidget {
  const MyBusinessesSection({super.key});

  @override
  State<MyBusinessesSection> createState() => _MyBusinessesSectionState();
}

class _MyBusinessesSectionState extends State<MyBusinessesSection> {
  Stream<QuerySnapshot>? _businessesStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _businessesStream = FirebaseFirestore.instance
          .collection('places')
          .where('ownerId', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _businessesStream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;

        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                "GESTIÓN DE MIS LOCALES",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String placeId = doc.id;
              final String placeName = data['name'] ?? 'Mi Bar';
              final String? photoUrl = (data['fotos'] as List?)?.firstOrNull;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final bool isOwner = data['ownerId'] == uid;

                      final List<String> superAdmins = [
                        'TpOkGBVXlLZVSQhfCdCrZ6R82g42',
                        'okkS6brpDKg9FYkOqYp9t5OfPTv2',
                      ];

                      final bool isSuperAdmin =
                          uid != null && superAdmins.contains(uid);

                      if (isOwner && !isSuperAdmin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PanelDuenoScreen(placeId: placeId),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(placeId: placeId),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Logo del lugar
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orangeAccent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              image: photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(photoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: photoUrl == null
                                ? const Icon(
                                    Icons.store,
                                    color: Colors.orangeAccent,
                                    size: 28,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Información
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Toca para abrir el panel de control",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Icono de flecha
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
