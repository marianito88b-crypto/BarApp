import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/services/guest_guard.dart';
import 'glass_icon_button.dart';
import 'package:barapp/ui/widgets/user_avatar.dart';

/// Header superior del feed con perfil y botones de acción
/// 
/// Maneja los botones premium y el perfil del usuario
class HomeTopHeader extends StatefulWidget {
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
  State<HomeTopHeader> createState() => _HomeTopHeaderState();
}

class _HomeTopHeaderState extends State<HomeTopHeader> {
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .snapshots();
    }
  }

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
              onTap: widget.onOpenProfile,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: uid != null
                        ? StreamBuilder<DocumentSnapshot>(
                            stream: _userStream,
                            builder: (context, snapshot) {
                              String? photoUrl;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data() as Map<String, dynamic>?;
                                photoUrl = data?['imageUrl'];
                              }
                              photoUrl ??= user?.photoURL;
                              return UserAvatar(
                                imageUrl: photoUrl,
                                radius: 18,
                              );
                            },
                          )
                        : const UserAvatar(radius: 18),
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
            onTap: () => GuestGuard.run(context, action: widget.onOpenOrders),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.groups_2_rounded,
            color: const Color(0xFF2EC4B6), // Borde Turquesa
            tooltip: 'Conectados',
            onTap: () => GuestGuard.run(context, action: widget.onOpenConnected),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFFCB6CE6), // Borde Violeta
            tooltip: 'Mensajes',
            onTap: () => GuestGuard.run(context, action: widget.onOpenChat),
          ),
          const SizedBox(width: 8),

          GlassIconButton(
            icon: Icons.settings_rounded,
            color: Colors.blueGrey.shade200, // Borde Plata
            tooltip: 'Configuración',
            onTap: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }
}
