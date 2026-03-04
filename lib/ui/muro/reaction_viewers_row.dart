import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/widgets/user_avatar.dart';

class ReactionViewersRowGeneral extends StatefulWidget {
  final DocumentReference postReference;
  final void Function(String userId, String displayName, String photoUrl)? onUserTap;

  const ReactionViewersRowGeneral({
    super.key,
    required this.postReference,
    this.onUserTap,
  });

  @override
  State<ReactionViewersRowGeneral> createState() => _ReactionViewersRowGeneralState();
}

class _ReactionViewersRowGeneralState extends State<ReactionViewersRowGeneral> {
  late final Stream<DocumentSnapshot> _postStream;

  @override
  void initState() {
    super.initState();
    _postStream = widget.postReference.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _postStream,
      builder: (context, snap) {
        // Validaciones iniciales para no ensuciar el log
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = (snap.data!.data() ?? {}) as Map<String, dynamic>;
        final raw = data['reaccionesUsuarios'];

        if (raw == null || raw is! Map) return const SizedBox.shrink();

        final Map<String, dynamic> reaccionesUsuariosRaw = Map<String, dynamic>.from(raw);

        // Juntamos UIDs únicos
        final Set<String> userIds = {};
        reaccionesUsuariosRaw.forEach((emoji, lista) {
          for (final uid in List<String>.from(lista ?? const [])) {
            userIds.add(uid);
          }
        });

        if (userIds.isEmpty) return const SizedBox.shrink();

        final ids = userIds.toList();
        final visibles = ids.take(6).toList(); // Mostramos hasta 6 caritas
        final extra = ids.length - visibles.length;

        // 🔥 CAMBIO CLAVE: Usamos _fetchUsersIndividual en lugar de whereIn
        return FutureBuilder<List<DocumentSnapshot>>(
          future: _fetchUsersIndividual(visibles),
          builder: (context, snapUsers) {
            
            // Si está cargando o dio error, mostramos vacío (sin error rojo)
            if (snapUsers.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 28, width: 28); 
            }

            if (snapUsers.hasError || !snapUsers.hasData || snapUsers.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final docs = snapUsers.data!;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                ...docs.map((doc) {
                  // Validación extra por si el doc no existe (usuario borrado)
                  if (!doc.exists) return const SizedBox.shrink();

                  final uData = doc.data() as Map<String, dynamic>;
                  final name = (uData['displayName'] ?? uData['nombre'] ?? 'U').toString();
                  final avatarUrl = (uData['imageUrl'] ?? uData['photoUrl'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onUserTap != null) {
                          widget.onUserTap!(doc.id, name, avatarUrl);
                        }
                      },
                      child: UserAvatar(
                        imageUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                        radius: 14,
                      ),
                    ),
                  );
                }),
                if (extra > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 LÓGICA PLAN C: Buscar uno por uno (paralelo)
  // Esto evita el problema de permisos de "listar usuarios"
  Future<List<DocumentSnapshot>> _fetchUsersIndividual(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];
      
      // Creamos una lista de futuros (peticiones individuales)
      final futures = uids.map((id) => 
        FirebaseFirestore.instance.collection('usuarios').doc(id).get()
      );
      
      // Esperamos a que todas terminen
      final results = await Future.wait(futures);
      
      // Filtramos solo los que existen (por si alguno borró su cuenta)
      return results.where((doc) => doc.exists).toList();
      
    } catch (e) {
      debugPrint("⚠️ Error silencioso fetching users: $e");
      return []; // Devolvemos lista vacía para no romper la UI
    }
  }
}