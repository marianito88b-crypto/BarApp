import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/superadmin/super_admin_dashboard_screen.dart';
import 'package:barapp/ui/panel_dueno/panel_dueno_screen.dart';
import 'modals/followed_bars_modal.dart';
import 'modals/my_gifts_modal.dart';
import 'package:barapp/ui/user/widgets/profile/client_ratings_modal.dart';

/// Barra de acciones rápidas: 4 círculos en horizontal.
/// Reseñas de bares | Gestiona tu bar | Bares que seguís | Mis regalos
class ProfileQuickActionsBar extends StatelessWidget {
  final bool isAdmin;
  final bool isOwnProfile;
  final Color accentColor;
  final String? userId;

  const ProfileQuickActionsBar({
    super.key,
    required this.isAdmin,
    required this.isOwnProfile,
    required this.accentColor,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [];
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    // Admin: Panel de moderación (primero si aplica)
    if (isAdmin) {
      actions.add(
        _GlassActionButton(
          icon: Icons.shield_rounded,
          tooltip: 'Panel de moderación',
          accentColor: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminDashboardScreen(),
              ),
            );
          },
        ),
      );
    }

    // 4 círculos: Reseñas | Gestiona | Bares seguidos | Mis regalos
    if (isOwnProfile && currentUserId != null) {
      actions.add(
        _GlassActionButton(
          icon: Icons.star_rounded,
          tooltip: 'Reseñas de bares',
          accentColor: Colors.blueAccent,
          onTap: () => ClientRatingsModal.show(context, currentUserId),
        ),
      );
      actions.add(
        _GlassActionButton(
          icon: Icons.store_rounded,
          tooltip: 'Gestiona tu bar',
          accentColor: accentColor,
          onTap: () => _showMyBusinessesModal(context),
        ),
      );
      actions.add(
        _GlassActionButton(
          icon: Icons.favorite_rounded,
          tooltip: 'Bares que seguís',
          accentColor: accentColor,
          onTap: () => _showFollowedBarsModal(context),
        ),
      );
      actions.add(
        _GlassActionButton(
          icon: Icons.card_giftcard_rounded,
          tooltip: 'Mis regalos',
          accentColor: Colors.purpleAccent,
          onTap: () => MyGiftsModal.show(context, currentUserId),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: action,
                ))
            .toList(),
      ),
    );
  }

  void _showMyBusinessesModal(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MyBusinessesModal(uid: uid),
    );
  }

  void _showFollowedBarsModal(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final data = userDoc.data();
      if (data == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar la información'),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }
      final List<String> followingBars =
          List<String>.from((data['followingBars'] as List?) ?? []);

      if (followingBars.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No seguís ningún bar aún'),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => FollowedBarsModal(followingBars: followingBars),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar bares seguidos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Botón con efecto glass y icono redondo
class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal para gestionar mis negocios
class _MyBusinessesModal extends StatelessWidget {
  final String uid;

  const _MyBusinessesModal({required this.uid});

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
                  const Text(
                    'Mis Locales',
                    style: TextStyle(
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

            // Lista de negocios
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('ownerId', isEqualTo: uid)
                    .snapshots(),
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

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No tenés locales registrados',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>?;
                      final placeId = doc.id;
                      final name = data?['nombre'] ?? data?['name'] ?? 'Mi Bar';
                      final String? photoUrl = (data?['fotos'] as List?)?.firstOrNull;

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
                                photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
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
                            'Toca para abrir el panel de control',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PanelDuenoScreen(placeId: placeId),
                              ),
                            );
                          },
                        ),
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
