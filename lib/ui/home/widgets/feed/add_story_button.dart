import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/widgets/user_avatar.dart';

/// Botón para agregar una nueva historia
/// 
/// Muestra el avatar del usuario con un ícono "+" y el texto "Subir historia"
class AddStoryButton extends StatefulWidget {
  final VoidCallback onTap;

  const AddStoryButton({
    super.key,
    required this.onTap,
  });

  @override
  State<AddStoryButton> createState() => _AddStoryButtonState();
}

class _AddStoryButtonState extends State<AddStoryButton> {
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

    // Fallbacks iniciales
    String displayName = user?.displayName ?? '?';
    String initials = displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

    return SizedBox(
      width: 65.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (uid != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: _userStream,
                    builder: (context, snapshot) {
                      String? photoUrl;

                      // Intentar leer de Firestore
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        photoUrl = data?['imageUrl'];

                        // Actualizar nombre/iniciales si cambió en base de datos
                        final firestoreName = data?['displayName'] as String?;
                        if (firestoreName != null && firestoreName.isNotEmpty) {
                          initials = firestoreName.substring(0, 1).toUpperCase();
                        }
                      }

                      // Fallback a Auth
                      photoUrl ??= user?.photoURL;

                      return UserAvatar(imageUrl: photoUrl, radius: 26);
                    },
                  )
                else
                  CircleAvatar(radius: 26, child: Text(initials)),

                // El ícono "+"
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF121212), width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Subir historia',
            style: TextStyle(fontSize: 8, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}
