import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/services/guest_guard.dart';
import 'glass_icon_button.dart';

/// Header superior del feed con perfil y botones de acción
/// 
/// Maneja los botones premium y el perfil del usuario
class HomeTopHeader extends StatelessWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenConnected;
  final VoidCallback onOpenOrders;

  const HomeTopHeader({
    super.key,
    required this.onOpenProfile,
    required this.onOpenChat,
    required this.onOpenSettings,
    required this.onOpenConnected,
    required this.onOpenOrders,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          // PERFIL
          Expanded(
            child: GestureDetector(
              onTap: onOpenProfile,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: uid != null
                        ? StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String? photoUrl;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data() as Map<String, dynamic>?;
                                photoUrl = data?['imageUrl'];
                              }
                              photoUrl ??= user?.photoURL;
                              return CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF1E1E1E),
                                backgroundImage: (photoUrl != null &&
                                        photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? const Icon(Icons.person_rounded,
                                        color: Colors.white54, size: 20)
                                    : null,
                              );
                            },
                          )
                        : const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF1E1E1E),
                            child: Icon(Icons.person, color: Colors.white54),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.isAnonymous == true
                              ? 'Invitado'
                              : (user?.displayName ?? 'Mi perfil'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (user?.isAnonymous != true)
                          const Text('Ver perfil',
                              style: TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTONES PREMIUM ---
          GlassIconButton(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFFF9F1C), // Borde Naranja
            tooltip: 'Mis Pedidos',
            onTap: () => GuestGuard.run(context, action: onOpenOrders),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.groups_2_rounded,
            color: const Color(0xFF2EC4B6), // Borde Turquesa
            tooltip: 'Conectados',
            onTap: () => GuestGuard.run(context, action: onOpenConnected),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFFCB6CE6), // Borde Violeta
            tooltip: 'Mensajes',
            onTap: () => GuestGuard.run(context, action: onOpenChat),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.settings_rounded,
            color: Colors.blueGrey.shade200, // Borde Plata
            tooltip: 'Configuración',
            onTap: onOpenSettings,
          ),
        ],
      ),
    );
  }
}
