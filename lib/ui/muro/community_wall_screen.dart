// lib/ui/community/community_wall_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// TUS IMPORTS (Asegurate que las rutas estén bien)
import '../../models/unified_post.dart';
import 'package:barapp/ui/community/post_card_general.dart';
import 'widgets/comment_modal.dart';
import 'new_post_screen.dart';
import '../place/place_detail_screen.dart';
import 'package:barapp/ui/user/user_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/blocked_users_provider.dart';

class CommunityWallScreen extends StatefulWidget {
  const CommunityWallScreen({super.key});

  @override
  State<CommunityWallScreen> createState() => _CommunityWallScreenState();
}

class _CommunityWallScreenState extends State<CommunityWallScreen> {
  StreamSubscription? _subComunidad;

  final List<UnifiedPost> _comunidadPosts = [];
  final Set<String> _preloadedImages = {};
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    // 1) COMUNIDAD
    _subComunidad = FirebaseFirestore.instance
        .collection('comunidad')
        .orderBy('destacado', descending: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _comunidadPosts.clear();
            for (final d in snap.docs) {
              final data = (d.data());
              _comunidadPosts.add(
                UnifiedPost(
                  reference: d.reference,
                  map: {
                    ...data,
                    'authorName':
                        data['authorName'] ?? data['displayName'] ?? 'Usuario',
                    'timestamp':
                        data['timestamp'] ?? data['fecha'] ?? Timestamp.now(),
                    'placeName': data['placeName'] ?? 'Comunidad',
                  },
                  destacado: data['destacado'] == true,
                  ts:
                      (data['timestamp'] ?? data['fecha']) as Timestamp? ??
                      Timestamp.now(),
                ),
              );
            }
            // Precargar imágenes de los primeros posts
            _preloadPostImages();
          });
        });

    // 2) POSTS DE LOCALES
  }

  /// Precarga imágenes de los primeros posts para mejor UX
  Future<void> _preloadPostImages() async {
    if (_isPreloading || _comunidadPosts.isEmpty) return;
    _isPreloading = true;

    // Precargar primeras 5 imágenes de posts y avatares
    final postsToPreload = _comunidadPosts.take(5).toList();
    
    for (final post in postsToPreload) {
      if (!mounted) return;
      final data = post.map;

      // Precargar imagen del post
      final imageUrl = (data['imageUrl'] ?? '') as String;
      if (imageUrl.isNotEmpty && !_preloadedImages.contains(imageUrl)) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          );
          if (!mounted) return;
          _preloadedImages.add(imageUrl);
        } catch (e) {
          debugPrint('Error precargando imagen de post: $e');
        }
      }

      // Precargar avatar del autor
      final authorPhotoUrl = (data['authorPhotoUrl'] ??
                             data['authorPhotoURL'] ??
                             data['imageUrl'] ??
                             '') as String;
      if (authorPhotoUrl.isNotEmpty &&
          authorPhotoUrl != imageUrl &&
          !_preloadedImages.contains(authorPhotoUrl)) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(authorPhotoUrl),
            context,
          );
          if (!mounted) return;
          _preloadedImages.add(authorPhotoUrl);
        } catch (e) {
          debugPrint('Error precargando avatar: $e');
        }
      }
    }

    _isPreloading = false;
  }

  @override
  void dispose() {
    _subComunidad?.cancel();

    super.dispose();
  }

  Future<void> _handleReaction(
    DocumentReference postRef,
    String emoji,
    String uid,
  ) async {
    // (Tu lógica de transacción intacta para evitar conflictos)
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return; // Protección extra
      final data = (snap.data() ?? {}) as Map<String, dynamic>;

      final Map<String, dynamic> reacciones = Map.from(
        data['reacciones'] ?? {},
      );
      final Map<String, dynamic> reaccionesUsuariosRaw = Map.from(
        data['reaccionesUsuarios'] ?? {},
      );

      final Map<String, List<String>> reaccionesUsuarios = {
        for (final key in reaccionesUsuariosRaw.keys)
          key: List<String>.from(reaccionesUsuariosRaw[key] ?? const []),
      };

      final List<String> listaActual = List.from(
        reaccionesUsuarios[emoji] ?? const [],
      );
      final bool yaReacciono = listaActual.contains(uid);

      if (yaReacciono) {
        listaActual.remove(uid);
        if (listaActual.isEmpty) {
          reaccionesUsuarios.remove(emoji);
          reacciones.remove(emoji);
        } else {
          reaccionesUsuarios[emoji] = listaActual;
          reacciones[emoji] = listaActual.length;
        }
      } else {
        // Quitar otras reacciones previas
        for (final entry in reaccionesUsuarios.entries.toList()) {
          final lista = entry.value;
          if (lista.remove(uid)) {
            if (lista.isEmpty) {
              reaccionesUsuarios.remove(entry.key);
              reacciones.remove(entry.key);
            } else {
              reaccionesUsuarios[entry.key] = lista;
              reacciones[entry.key] = lista.length;
            }
          }
        }
        // Agregar nueva
        final nuevaLista = List<String>.from(
          reaccionesUsuarios[emoji] ?? const [],
        );
        nuevaLista.add(uid);
        reaccionesUsuarios[emoji] = nuevaLista;
        reacciones[emoji] = nuevaLista.length;
      }

      tx.update(postRef, {
        'reacciones': reacciones,
        'reaccionesUsuarios': reaccionesUsuarios,
      });
    });
  }

  void _showCommentModal(BuildContext context, DocumentReference postRef) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentModal(postRef: postRef),
    );
  }

  void _showPostOptions(
    BuildContext context,
    UnifiedPost item,
    BlockedUsersProvider blockedProvider,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final data = item.map;
    final ref = item.reference;
    final String? authorId = data['authorId'] ?? data['uid'] ?? data['userId'];
    final String authorName = data['authorName'] ?? 'Usuario';
    final String authorPhoto = data['authorPhotoUrl'] ?? '';
    final bool isDestacado = data['destacado'] == true;

    // Lógica de permisos
    final bool isAdmin =
        (currentUser != null && _superAdmins.contains(currentUser.uid));
    final bool isOwner = (currentUser != null && authorId == currentUser.uid);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- SECCIÓN PARA TODOS LOS USUARIOS ---

              // 1. REPORTAR (Requisito Google)
              ListTile(
                leading: const Icon(
                  Icons.report_gmailerrorred_rounded,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  'Reportar publicación',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog(context, ref, authorId);
                },
              ),

              // 2. BLOQUEAR (Si no soy yo)
              if (authorId != null && authorId != currentUser?.uid)
                ListTile(
                  leading: const Icon(
                    Icons.person_off_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    'Bloquear a $authorName',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await blockedProvider.block(
                      authorId,
                      name: authorName,
                      photoUrl: authorPhoto,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bloqueaste a $authorName')),
                      );
                    }
                  },
                ),

              const Divider(color: Colors.white10),

              // --- SECCIÓN EXCLUSIVA PARA ADMINS (DESTACAR) ---
              if (isAdmin)
                ListTile(
                  leading: Icon(
                    isDestacado
                        ? Icons.star_border_rounded
                        : Icons.star_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(
                    isDestacado ? 'Quitar destacado' : 'Destacar publicación',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.update({'destacado': !isDestacado});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isDestacado
                                ? 'Se quitó el destacado'
                                : '¡Publicación destacada!',
                          ),
                          backgroundColor:
                              isDestacado ? Colors.grey : Colors.amber,
                        ),
                      );
                    }
                  },
                ),

              // 3. ELIMINAR (Si es admin o dueño)
              if (isOwner || isAdmin)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Eliminar publicación',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Confirmación rápida antes de borrar
                    final bool? confirmar = await showDialog(
                      context: context,
                      builder:
                          (c) => AlertDialog(
                            backgroundColor: const Color(0xFF242526),
                            title: const Text(
                              "¿Borrar?",
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text(
                                  "Sí",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirmar == true) await ref.delete();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(
    BuildContext context,
    DocumentReference postRef,
    String? authorId,
  ) {
    final List<String> motivos = [
      'Contenido inapropiado',
      'Spam',
      'Acoso',
      'Violencia',
      'Otros',
    ];
    String motivoSeleccionado = motivos[0];
    final TextEditingController detallesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            // Necesario para que el dropdown funcione dentro del dialog
            builder:
                (context, setModalState) => AlertDialog(
                  backgroundColor: const Color(0xFF242526),
                  title: const Text(
                    'Reportar publicación',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Motivo:",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        // DROPDOWN DE MOTIVOS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: motivoSeleccionado,
                            dropdownColor: const Color(0xFF242526),
                            isExpanded: true,
                            underline: const SizedBox(),
                            items:
                                motivos.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setModalState(
                                () => motivoSeleccionado = newValue!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Cuéntanos más (opcional):",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        // CAMPO DE TEXTO PARA EXPLICACIÓN
                        TextField(
                          controller: detallesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Escribe aquí los detalles...",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final detalles = detallesController.text.trim();
                        Navigator.pop(ctx);

                        try {
                          await FirebaseFirestore.instance
                              .collection('reports')
                              .add({
                                'postId': postRef.id,
                                'postPath': postRef.path,
                                'reporterId':
                                    FirebaseAuth.instance.currentUser?.uid,
                                'authorId': authorId,
                                'reason': motivoSeleccionado,
                                'details': detalles, // 🔥 Nuevo campo
                                'timestamp': FieldValue.serverTimestamp(),
                                'status': 'pending',
                              });
                          if (context.mounted) {
                            _showSuccessReportDialog(context);
                          }
                        } catch (e) {
                          // Error de permisos o red
                        }
                      },
                      child: const Text('Enviar Reporte'),
                    ),
                  ],
                ),
          ),
    );
  }

  // NUEVO: El cartel de confirmación visual
  void _showSuccessReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF242526),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Reporte recibido",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Gracias por ayudarnos a cuidar la comunidad de BarApp. Evaluaremos el contenido y tomaremos medidas al respecto en menos de 24 horas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Entendido"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // 1. LISTA DE SUPER ADMINS (Pon tu UID aquí)
  final List<String> _superAdmins = [
    'TpOkGBVXlLZVSQhfCdCrZ6R82g42', // <--- PEGA TU UID AQUÍ PARA TENER PODERES
    'okkS6brpDKg9FYkOqYp9t5OfPTv2',
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final blockedProvider = Provider.of<BlockedUsersProvider>(context);

    // 1. Obtenemos la lista de IDs bloqueados
    final List<String> excludedIds = blockedProvider.excludedIds.toList();

    // 2. Filtramos ANTES de ordenar
    // 2. Filtramos ANTES de ordenar
    final List<UnifiedPost> combinedPosts =
        [..._comunidadPosts].where((post) {
          final map = post.map;

          // Intentamos obtener el ID del creador con varios nombres comunes
          final String? creatorId =
              map['authorId'] ?? map['uid'] ?? map['userId'];

          // Si encontramos un ID, verificamos si está en la lista negra
          if (creatorId != null) {
            // Si excludedIds contiene este ID, devolvemos false (ocultar)
            // Si NO lo contiene, devolvemos true (mostrar)
            return !excludedIds.contains(creatorId);
          }

          // Si no tiene ID de creador (ej: es un anuncio del sistema), lo mostramos
          return true;
        }).toList();

    combinedPosts.sort((a, b) {
      if (a.destacado != b.destacado) return a.destacado ? -1 : 1;
      return b.ts.compareTo(a.ts);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      appBar: AppBar(
        title: const Text(
          'Muro Social',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF242526),
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NuevaPublicacionScreen()),
            ),
      ),
      body:
          combinedPosts.isEmpty
              ? Center(child: const CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: combinedPosts.length,
                cacheExtent: 1000,
                itemBuilder: (context, index) {
                  final item =
                      combinedPosts[index]; // El objeto UnifiedPost completo
                  final data = item.map;
                  final ref = item.reference;

                  // --- Lógica de permisos ---
                  final bool isDestacado = data['destacado'] == true;

                  return PostCardGeneral(
                    key: ValueKey(ref.id),
                    data: data,
                    postReference: ref,
                    isFeatured: isDestacado,

                    // 🔥 TODO EL PODER AQUÍ (Reportar, Bloquear, Destacar, Eliminar)
                    onMoreTap:
                        () => _showPostOptions(context, item, blockedProvider),

                    onReact: (emoji) async {
                      if (currentUser == null) return;
                      await _handleReaction(ref, emoji, currentUser.uid);
                    },
                    onCommentTap: () => _showCommentModal(context, ref),
                    onDelete: null, // Ya no lo necesitamos aquí
                    onPlaceTap:
                        (placeId, _) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(placeId: placeId),
                          ),
                        ),
                    onUserTap:
                        (userId, name, photo) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => UserProfileScreen(
                                  externalUserId: userId,
                                  externalUserName: name,
                                  externalUserPhotoUrl: photo,
                                ),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}
