import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- ¡AÑADIDO!
import 'package:firebase_storage/firebase_storage.dart'; // <-- ¡AÑADIDO!
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // 👈 para mapEquals, arriba del archivo
import 'package:barapp/ui/user/user_profile_screen.dart';
import '../../services/moderation/text_filter_service.dart'; // <--- AGREGAR
import 'dart:ui'; // <--- ESTA ES LA QUE FALTA


// --- ¡IMPORT CORREGIDO! ---
import '../../models/story_item.dart';

// --- ¡CAMBIO #1: LÓGICA DE TIPO DE MEDIA MEJORADA! ---
// Ya no adivinamos por la URL, leemos el modelo.
enum _MediaType { image, video }
_MediaType _mediaTypeOf(StoryItem story) {
  return story.mediaType == 'video' ? _MediaType.video : _MediaType.image;
}

class StoryViewerScreen extends StatefulWidget {
  // ... (El constructor no cambia) ...
// [Immersive content redacted for brevity.]
  final List<StoryItem> stories;
  final int initialIndex;
  
  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late List<StoryItem> _stories;
  int _index = 0;

  final double _imageDurationSec = 5.0;
  Timer? _imageTimer;
  double _imageProgress = 0.0;
  bool _paused = false;
  bool _isLoadingDelete = false;

  VideoPlayerController? _video;

  String? _currentUserId;
  String? _myReaction; 

@override
  void initState() {
    super.initState();
    _stories = widget.stories;
    _index = widget.initialIndex.clamp(0, _stories.length - 1);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    final story = _stories[_index];
    _myReaction = story.reactionsUsers[_currentUserId];
    
    _loadCurrent(); // Esto carga la historia y ahora registrará la vista
  }

  @override
  void dispose() {
    _cancelImageTimer();
    _disposeVideo();
    super.dispose();
  }

  void _cancelImageTimer() {
    _imageTimer?.cancel();
    _imageTimer = null;
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
  }
// --- 👁️ NUEVA FUNCIÓN: REGISTRAR VISTA ---
  Future<void> _markAsSeen(StoryItem story) async {
    final uid = _currentUserId;
    // Si no hay usuario o si el usuario YA está en la lista de viewers, no hacemos nada.
    if (uid == null) return;
    if (story.viewers.contains(uid)) return;

    // 1. Actualizamos localmente para evitar llamadas repetidas inmediatas
    // (Opcional, pero buena práctica de optimización)
    final updatedViewers = List<String>.from(story.viewers)..add(uid);
    final updatedStory = story.copyWith(viewers: updatedViewers);
    
    if (mounted) {
      setState(() {
        _stories[_index] = updatedStory;
      });
    }

    // 2. Actualizamos en Firestore (Silenciosamente)
    try {
      await FirebaseFirestore.instance.collection('stories').doc(story.id).update({
        'viewers': FieldValue.arrayUnion([uid])
      });
      // debugPrint("Vista registrada para la historia ${story.id}");
    } catch (e) {
      debugPrint("Error registrando vista: $e");
    }
  }
 
Future<void> _loadCurrent() async {
    _cancelImageTimer();
    _imageProgress = 0.0;

    final current = _stories[_index];

    // 🔥 REGISTRAMOS LA VISTA AL CARGAR
    _markAsSeen(current);

    // 👉 CASO IMAGEN
    if (_mediaTypeOf(current) == _MediaType.image) {
      _disposeVideo();

      if (mounted) setState(() {});

      if (!_paused) {
        const stepSeconds = 0.02; 
        final totalTicks = (_imageDurationSec / stepSeconds).round();
        int ticks = 0;

        _imageTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
          if (_paused) return;

          ticks++;
          _imageProgress = ticks / totalTicks;

          if (!mounted) return;
          setState(() {});

          if (_imageProgress >= 1.0) {
            t.cancel();
            _next();
          }
        });
      }
      return;
    }

    // 👉 CASO VIDEO
    _disposeVideo(); 

    File fileToUse;
    try {
      fileToUse = await DefaultCacheManager().getSingleFile(current.mediaUrl);
    } catch (e) {
      debugPrint('Error obteniendo archivo de video: $e');
      if (mounted) _next();
      return;
    }

    try {
      _video = VideoPlayerController.file(fileToUse);
      await _video!.initialize();
      _video!.setLooping(false);
    } catch (e) {
      debugPrint('Error inicializando video de historia: $e');
      if (mounted) _next();
      return;
    }

    final ctrl = _video!;

    if (mounted) setState(() {});

    if (!_paused && ctrl.value.isInitialized) {
      await ctrl.play();
    }

    ctrl.addListener(() {
      if (!mounted || _video != ctrl || !ctrl.value.isInitialized) return;

      final v = ctrl.value;
      final dur = v.duration.inMilliseconds;
      final pos = v.position.inMilliseconds;

      if (dur > 0) {
        final newProgress = (pos / dur).clamp(0.0, 1.0);

        if ((newProgress - _imageProgress).abs() > 0.01 || pos >= dur) {
          _imageProgress = newProgress;
          if (mounted) {
            setState(() {});
          }
        }

        if (pos >= dur - 100 && !v.isPlaying && !_paused) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && _video == ctrl && !_paused) {
              _next();
            }
          });
        }
      }
    });
  }


 

void _togglePause(bool pause) async {
    _paused = pause;
    if (_mediaTypeOf(_stories[_index]) == _MediaType.video) {
      final v = _video;
      if (v != null && v.value.isInitialized) {
        if (pause) {
          await v.pause();
        } else {
          await v.play();
        }
      }
    }
    setState(() {});
  }

void _next() {
  if (_index < _stories.length - 1) {
    _cancelImageTimer();
    _index++;

    final story = _stories[_index];
    _myReaction = story.reactionsUsers[_currentUserId];

    _loadCurrent();
    if (mounted) setState(() {});
  } else {
    Navigator.of(context).maybePop();
  }
}

void _prev() {
  if (_index > 0) {
    _cancelImageTimer();
    _index--;

    final story = _stories[_index];
    _myReaction = story.reactionsUsers[_currentUserId];

    _loadCurrent();
    if (mounted) setState(() {});
  } else {
    Navigator.of(context).maybePop();
  }
}

  // --- ¡CAMBIO #4: LÓGICA DE TIEMPO ACTUALIZADA! ---
  String _timeElapsedText(StoryItem s) {
    final now = DateTime.now();
    final createdAt = s.createdAt.toDate();
    final diff = now.difference(createdAt);

    if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    }
    final m = diff.inMinutes.clamp(1, 59); // Mínimo 1 minuto
    return '${m}m';
  }

  // --- ¡CAMBIO #5: AÑADIDA LÓGICA PARA ELIMINAR! ---
  Future<void> _deleteStory() async {
    if (_isLoadingDelete) return;
    
    final story = _stories[_index];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    if (story.authorId != currentUid) return; // Doble chequeo de seguridad

    setState(() => _isLoadingDelete = true);
    Navigator.of(context).pop(); // Cierra el modal de opciones
    _togglePause(true); // Pausa la historia

    try {
      // 1. Eliminar de Firestore
      await FirebaseFirestore.instance.collection('stories').doc(story.id).delete();

      // 2. Eliminar de Storage (¡importante!)
      await FirebaseStorage.instance.refFromURL(story.mediaUrl).delete();

      // 3. Si todo ok, cerramos el visor
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error al eliminar historia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la historia.')),
        );
        _togglePause(false); // Quita la pausa si falló
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDelete = false);
      }
    }
  }

  void _showOptions() {
    final story = _stories[_index];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    // Solo mostramos opciones si es MI historia
    if (story.authorId != currentUid) return;

    _togglePause(true); // Pausamos

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Un gris oscuro elegante
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
              ),
            ),
            const SizedBox(height: 20),
            
            // --- 👁️ AQUÍ EL CAMBIO: MUESTRA AVATARES, NO NÚMEROS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                story.viewers.isEmpty ? "Sin vistas aún" : "Visto por:", 
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 10),
            
            // Widget que carga y muestra las caritas
            _ViewersAvatarsRow(viewerIds: story.viewers),
            
            const SizedBox(height: 10),
            const Divider(color: Colors.white10),

            // Dentro de _showOptions(), añade este ListTile antes o después del de eliminar:
ListTile(
  leading: Icon(
    story.isFeatured ? Icons.star_border_rounded : Icons.star_rounded, 
    color: Colors.amber
  ),
  title: Text(
    story.isFeatured ? 'Quitar Destacado' : 'Destacar Historia',
    style: const TextStyle(color: Colors.white)
  ),
  onTap: () async {
    Navigator.pop(context); // Cerrar modal
    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(story.id)
          .update({'isFeatured': !story.isFeatured});
      
      // Actualizamos localmente
      setState(() {
        _stories[_index] = story.copyWith(isFeatured: !story.isFeatured);
      });
    } catch (e) {
      debugPrint("Error al destacar: $e");
    }
  },
),

            // Opción Eliminar
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Eliminar Historia', style: TextStyle(color: Colors.redAccent)),
              onTap: _deleteStory,
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).whenComplete(() {
      if (!_isLoadingDelete) {
        _togglePause(false); // Reanudamos al cerrar
      }
    });
  }

Future<void> _toggleReaction(String emoji) async {
  final uid = _currentUserId;
  if (uid == null) return;

  final current = _stories[_index];
  final docRef = FirebaseFirestore.instance
      .collection('stories')
      .doc(current.id);

  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      final Map<String, int> reactions =
          Map<String, int>.from(data['reactions'] ?? {});
      final Map<String, String> reactionsUsers =
          Map<String, String>.from(
            (data['reactionsUsers'] ?? {}).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          );

      final String? prevEmoji = reactionsUsers[uid];

      // Caso 1: ya tiene esa reacción → la quitamos
      if (prevEmoji == emoji) {
        reactionsUsers.remove(uid);
        if (reactions.containsKey(emoji)) {
          final newCount = reactions[emoji]! - 1;
          if (newCount <= 0) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = newCount;
          }
        }
      } else {
        // Caso 2: tenía otra reacción -> ajustamos conteos
        if (prevEmoji != null && reactions.containsKey(prevEmoji)) {
          final newCount = reactions[prevEmoji]! - 1;
          if (newCount <= 0) {
            reactions.remove(prevEmoji);
          } else {
            reactions[prevEmoji] = newCount;
          }
        }

        // Seteamos la nueva
        reactionsUsers[uid] = emoji;
        reactions[emoji] = (reactions[emoji] ?? 0) + 1;
      }

      tx.update(docRef, {
        'reactions': reactions,
        'reactionsUsers': reactionsUsers,
      });
    });

    // Volvemos a leer el doc para estar en sync:
    final freshSnap = await docRef.get();
    final freshStory = StoryItem.fromFirestore(
        freshSnap);

    setState(() {
      _stories[_index] = freshStory;
      _myReaction = freshStory.reactionsUsers[_currentUserId];
    });
  } catch (e) {
    debugPrint('Error toggling reacción: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la reacción.')),
      );
    }
  }
}
Widget _buildActionsBar(StoryItem story) {
  final totalReactions = story.reactions.values.fold<int>(0, (a, b) => a + b);

  // Emojis que vamos a usar como reacciones rápidas
  const emojis = ['🔥', '😍', '🍻', '😎'];

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Fila principal: reacciones rápidas + botón de comentarios
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reacciones rápidas
          Row(
            children: [
              for (final e in emojis)
                GestureDetector(
                  onTap: () => _toggleReaction(e),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _myReaction == e
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: _myReaction == e
                          ? Border.all(color: Colors.white, width: 1)
                          : null,
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              if (totalReactions > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '$totalReactions',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          // Botón de comentarios
          GestureDetector(
            onTap: () => _openComments(story),
            child: Row(
              children: [
                const Icon(
                  Icons.mode_comment_outlined,
                  size: 20,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  story.commentsCount > 0
                      ? story.commentsCount.toString()
                      : 'Comentar',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 6),

      // 👇 Nueva fila: quién reaccionó y con qué emoji
      _StoryReactionsViewersRow(
        reactionsUsers: story.reactionsUsers,
        currentUserId: _currentUserId,
      ),
    ],
  );
}

Future<void> _openComments(StoryItem story) async {
  final uid = _currentUserId;
  if (uid == null) return;

  _togglePause(true); // Pausar historia mientras se comenta

  final user = FirebaseAuth.instance.currentUser;
  final name = user?.displayName ?? 'Usuario';
  final photo = user?.photoURL;

  final TextEditingController controller = TextEditingController();
  bool sending = false;

  // Cache the comments stream before showing the modal
  final commentsStream = FirebaseFirestore.instance
      .collection('stories')
      .doc(story.id)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Comentarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (story.commentsCount > 0)
                  Text(
                    '${story.commentsCount}',
                    style: const TextStyle(color: Colors.white54),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de comentarios
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: commentsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sé el primero en comentar ✨',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    reverse: true, // último abajo
                    itemCount: docs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = docs[i].data();
                      final text = (c['text'] ?? '') as String;
                      final authorName = (c['authorName'] ?? 'Usuario') as String;
                      final authorPhoto = c['authorPhotoUrl'] as String?;
                      final ts = c['createdAt'] as Timestamp?;
                      final time = ts?.toDate();

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            backgroundImage: (authorPhoto != null &&
                                    authorPhoto.isNotEmpty)
                                ? NetworkImage(authorPhoto)
                                : null,
                            child: (authorPhoto == null ||
                                    authorPhoto.isEmpty)
                                ? Text(
                                    authorName.isNotEmpty
                                        ? authorName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                if (time != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      time.toLocal().toString(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Caja de texto + botón enviar
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      (photo != null && photo.isNotEmpty)
                          ? NetworkImage(photo)
                          : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Añadir un comentario...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;

                          // 🧹 LIMPIEZA DE PALABRAS:
                          final String textClean = TextFilterService.sanitizeText(text);

                          setModalState(() => sending = true);

                          try {
                            final storyRef = FirebaseFirestore.instance
                                .collection('stories')
                                .doc(story.id);

                            await storyRef
                                .collection('comments')
                                .add({
                              'text': textClean, // <--- ENVIAMOS LIMPIO
                              'authorId': uid,
                              'authorName': name,
                              'authorPhotoUrl': photo,
                              'createdAt':
                                  FieldValue.serverTimestamp(),
                            });

                            await storyRef.update({
                              'commentsCount':
                                  FieldValue.increment(1),
                            });

                            controller.clear();

                            // refrescamos el story local
                            final fresh =
                                await storyRef.get();
                            final freshStory =
                                StoryItem.fromFirestore(
                                  fresh,
                                );

                            if (mounted) {
                              setState(() {
                                _stories[_index] = freshStory;
                              });
                            }
                          } catch (e) {
                            debugPrint(
                                'Error enviando comentario: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No se pudo enviar el comentario.'),
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) setModalState(() => sending = false);
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },),  // cierre StatefulBuilder
  ).whenComplete(() {
    controller.dispose(); // dispose del controlador al cerrar el modal
    if (mounted) _togglePause(false); // Reanudar al cerrar modal/teclado
  });
}

@override
Widget build(BuildContext context) {
  final story = _stories[_index];
  final isVideo = _mediaTypeOf(story) == _MediaType.video;

  return GestureDetector(
    onVerticalDragEnd: (_) => Navigator.of(context).maybePop(),
    onLongPressStart: (_) => _togglePause(true),
    onLongPressEnd: (_) => _togglePause(false),
    onTapUp: (d) {
      final w = MediaQuery.of(context).size.width;
      if (d.localPosition.dx > w * 0.5) {
        _next();
      } else {
        _prev();
      }
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
          // 1. FONDO Y CONTENIDO (CON EFECTO GLOW DORADO)
Positioned.fill(
  child: Container(
    // Si es destacada, aplicamos la decoración especial
    decoration: story.isFeatured ? BoxDecoration(
      // 1. El borde sólido para definir (un poco más fino ahora)
      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
      
      // 2. ¡AQUÍ ESTÁ LA MAGIA DEL BRILLO! ✨
      boxShadow: [
        // Capa interna: luz intensa pegada al borde
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.7), // Dorado intenso semi-transparente
          blurRadius: 12.0, // Qué tan borroso es
          spreadRadius: 2.0, // Qué tanto se expande desde el borde
        ),
        // Capa externa: halo de luz difusa más amplio
        BoxShadow(
          color: Colors.amber.shade600.withValues(alpha: 0.4), // Un ámbar más suave para el exterior
          blurRadius: 30.0, // Muy difuminado para que parezca luz
          spreadRadius: 10.0, // Se expande bastante
        ),
      ],
    ) : null, // Si no es destacada, no tiene decoración
    
    // El contenido (ClipRRect es opcional, pero ayuda si el borde se ve raro en las esquinas)
    child: ClipRRect(
      // Si querés bordes redondeados, descomentá esto:
      // borderRadius: BorderRadius.circular(story.isFeatured ? 12 : 0),
      child: isVideo
          ? _VideoView(controller: _video)
          : _ImageView(url: story.mediaUrl),
    ),
  ),
),

            // Overlay de carga al eliminar
            if (_isLoadingDelete)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),

            // TOP overlay: barras + header
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Column(
                children: [
                  _ProgressBars(
                    total: _stories.length,
                    current: _index,
                    currentProgress: _imageProgress.clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  _HeaderBar(
                    authorName: story.authorName,
                    authorPhotoUrl: story.authorPhotoUrl,
                    isFeatured: story.isFeatured,
                    extra: _timeElapsedText(story),
                    onClose: () => Navigator.of(context).maybePop(),
                    onShowOptions: _showOptions,
                    canShowOptions: story.authorId == _currentUserId,
                    paused: _paused,
                  ),
                ],
              ),
            ),

            // 👇 BOTTOM overlay: barra de acciones (REUBICADO AQUÍ)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildActionsBar(story),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// (Todos tus widgets _ImageView, _VideoView, _ProgressBars
//  estaban perfectos, van aquí sin cambios)

class _ImageView extends StatelessWidget {
  final String url;
  const _ImageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa 1: Fondo desenfocado (para que no se vea negro feo a los costados)
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        // Capa 2: La imagen real completa
        Positioned.fill(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain, // <--- ESTO HACE QUE SE VEA COMPLETA
              placeholder: (c, _) => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryReactionsViewersRow extends StatefulWidget {
  final Map<String, String> reactionsUsers; // uid -> emoji
  final String? currentUserId;

  const _StoryReactionsViewersRow({
    required this.reactionsUsers,
    required this.currentUserId,
  });

  @override
  State<_StoryReactionsViewersRow> createState() =>
      _StoryReactionsViewersRowState();
}

class _StoryReactionsViewersRowState
    extends State<_StoryReactionsViewersRow> {
  bool _loading = false;
  List<_ReactionUserInfo> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void didUpdateWidget(covariant _StoryReactionsViewersRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo recargamos si cambió el mapa de reacciones
    if (!mapEquals(oldWidget.reactionsUsers, widget.reactionsUsers)) {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    if (widget.reactionsUsers.isEmpty) {
      setState(() {
        _users = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final allUids = widget.reactionsUsers.keys.toList();
      // Firestore limita whereIn a 10 elementos
      final limitedUids = allUids.take(10).toList();

      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: limitedUids)
          .get();

      final users = snap.docs.map((d) {
        final data = d.data();
        final uid = d.id;
        final name = (data['displayName'] ??
                data['nombre'] ??
                'Usuario') as String;
        final photo = (data['imageUrl'] ??
                data['fotoPerfilUrl'] ??
                '') as String;
        final emoji = widget.reactionsUsers[uid] ?? '👍';

        return _ReactionUserInfo(
          uid: uid,
          name: name,
          photoUrl: photo,
          emoji: emoji,
        );
      }).toList();

      // Orden: primero el usuario actual si reaccionó
      users.sort((a, b) {
        if (a.uid == widget.currentUserId) return -1;
        if (b.uid == widget.currentUserId) return 1;
        return 0;
      });

      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando usuarios de reacciones: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reactionsUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Primera vez: solo loader
    if (_loading && _users.isEmpty) {
      return const SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = _users.take(4).toList();
    final extraCount = _users.length - visible.length;

    return Row(
      children: [
        // Avatares con emoji
        for (int i = 0; i < visible.length; i++)
          Padding(
            padding:
                EdgeInsets.only(right: i == visible.length - 1 ? 4 : 2),
            child: _ReactionUserAvatar(info: visible[i]),
          ),

        if (extraCount > 0)
          Text(
            '+$extraCount',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            _buildLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  String _buildLabel() {
    final me =
        _users.where((u) => u.uid == widget.currentUserId).toList();
    final others =
        _users.where((u) => u.uid != widget.currentUserId).toList();

    if (me.isNotEmpty && others.isEmpty) {
      return 'Te gustó esta historia';
    }

    if (me.isNotEmpty && others.isNotEmpty) {
      final firstOther = others.first;
      final extra = others.length - 1;
      if (extra <= 0) {
        return 'Vos y ${firstOther.name} reaccionaron';
      }
      return 'Vos, ${firstOther.name} y $extra más reaccionaron';
    }

    if (others.length == 1) {
      return '${others.first.name} reaccionó';
    }

    final first = others.first;
    final extra = others.length - 1;
    return '${first.name} y $extra más reaccionaron';
  }
}

class _ReactionUserInfo {
  final String uid;
  final String name;
  final String photoUrl;
  final String emoji;

  _ReactionUserInfo({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.emoji,
  });
}

class _ReactionUserAvatar extends StatelessWidget {
  final _ReactionUserInfo info;

  const _ReactionUserAvatar({required this.info});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => ProfileScreen(userId: info.uid),
        // ));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white24,
            backgroundImage: info.photoUrl.isNotEmpty
                ? NetworkImage(info.photoUrl)
                : null,
            child: info.photoUrl.isEmpty
                ? Text(
                    info.name.isNotEmpty
                        ? info.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                info.emoji,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoView extends StatelessWidget {
  final VideoPlayerController? controller;

  const _VideoView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
// ... (no cambia) ...
// [Immersive content redacted for brevity.]
  final int total;
  final int current;
  final double currentProgress;

  const _ProgressBars({
    required this.total,
    required this.current,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isCurrent = i == current;
        final value = i < current ? 1.0 : (isCurrent ? currentProgress : 0.0);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
            height: 3.2,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3.2,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String authorName;
  final String? authorPhotoUrl;
  final bool isFeatured;
  final String extra;
  final VoidCallback onClose;
  final VoidCallback onShowOptions;
  final bool canShowOptions; // solo mostrar el boton en historias propias
  final bool paused;

  const _HeaderBar({
    required this.authorName,
    required this.authorPhotoUrl,
    required this.isFeatured,
    required this.extra,
    required this.onClose,
    required this.onShowOptions,
    required this.canShowOptions,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    final photo = authorPhotoUrl;
    const Color goldColor = Color(0xFFFFD700); // El dorado

    return Row(
      children: [
        // --- AQUÍ ESTÁ EL CAMBIO: EL AVATAR CON GLOW ---
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Si es destacada, metemos el resplandor hacia afuera
            boxShadow: isFeatured ? [
              BoxShadow(
                color: goldColor.withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: goldColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ] : [],
          ),
          child: Container(
            // Un pequeño borde dorado extra para que se note la luz
            padding: EdgeInsets.all(isFeatured ? 2 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isFeatured ? Border.all(color: goldColor, width: 1.5) : null,
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
              child: (photo == null || photo.isEmpty)
                  ? Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?', 
                      style: const TextStyle(fontSize: 12, color: Colors.white))
                  : null,
            ),
          ),
        ),
        // --- FIN DEL CAMBIO ---

        const SizedBox(width: 10), // Un poquito más de espacio por el resplandor
        Expanded(
          child: Text(
            '$authorName${isFeatured ? " · ⭐" : ""} · $extra',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2)]
            ),
          ),
        ),
        if (paused)
          const Padding(
            padding: EdgeInsets.only(right: 6.0),
            child: Icon(Icons.pause_rounded, color: Colors.white70, size: 18),
          ),
        
        if (canShowOptions)
          IconButton(
            onPressed: onShowOptions,
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'Opciones',
            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.2)),
          ),

        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: 'Cerrar',
          style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}
class _ViewersAvatarsRow extends StatelessWidget {
  final List<String> viewerIds;

  const _ViewersAvatarsRow({required this.viewerIds});

  @override
  Widget build(BuildContext context) {
    if (viewerIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text("Sé el primero en ver esto... ah no, sos el dueño 😅", 
          style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
      );
    }

    // Limitamos a los últimos 10 y los invertimos para mostrar los más nuevos primero
    final idsToLoad = viewerIds.reversed.take(10).toList();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: idsToLoad)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 80, // Aumenté un poquito la altura para que entre bien el efecto touch
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16), // Más espacio entre caritas
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id; // ID del usuario para navegar
              final photo = data['imageUrl'] ?? data['fotoPerfilUrl'] ?? '';
              final name = data['displayName'] ?? data['nombre'] ?? 'Usuario';

              // ✨ AQUÍ ESTÁ LA MAGIA DE LA NAVEGACIÓN ✨
              return GestureDetector(
                onTap: () {
                  // 1. Cerramos el modal de las opciones para que no estorbe
                  // (Opcional: si prefieres que quede abierto al volver, borra esta línea)
                  // Navigator.pop(context); 

                  // 2. Navegamos al perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        externalUserId: uid,
                        externalUserName: name,
                        externalUserPhotoUrl: photo,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar con borde si quieres resaltarlo
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 22, // Un pelín más grande para que sea fácil de tocar
                        backgroundColor: Colors.grey[800],
                        backgroundImage: (photo.isNotEmpty) ? NetworkImage(photo) : null,
                        child: (photo.isEmpty) 
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Nombre limitado a un ancho para que no rompa el diseño
                    SizedBox(
                      width: 50, 
                      child: Text(
                        name, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}