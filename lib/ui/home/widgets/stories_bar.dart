import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/story_item.dart';
import 'package:barapp/screens/story_viewer_screen.dart' show StoryViewerScreen;


class StoryGroup {
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<StoryItem> stories;
  final bool isOwnStory;

  StoryGroup({
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.stories,
    this.isOwnStory = false,
  });
}

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<QuerySnapshot> _storiesStream;

  @override
  void initState() {
    super.initState();
    _storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _storiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final allItems = snapshot.data?.docs
            .map((doc) => StoryItem.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList() ?? [];

        final Map<String, List<StoryItem>> storiesByAuthor = {};
        for (final item in allItems) {
          (storiesByAuthor[item.authorId] ??= []).add(item);
        }

        final List<StoryGroup> storyGroups = [];
        StoryGroup? myStoryGroup;

        storiesByAuthor.forEach((authorId, stories) {
          if (stories.isEmpty) return;
          final firstStory = stories.first;
          final group = StoryGroup(
            authorId: authorId,
            authorName: firstStory.authorName,
            authorPhotoUrl: firstStory.authorPhotoUrl,
            stories: stories,
            isOwnStory: authorId == _currentUserId,
          );

          if (group.isOwnStory) {
            myStoryGroup = group;
          } else {
            storyGroups.add(group);
          }
        });
        
        // Lógica de ordenamiento
        if (myStoryGroup != null) {
          storyGroups.insert(0, myStoryGroup!);
        } else if (_currentUserId != null) {
          // AQUI ESTABA EL ERROR: No confiamos en la foto de Auth.
          // Pasamos null o lo que sea, porque el _StoryAvatar lo va a arreglar buscando en Firestore.
          storyGroups.insert(0, StoryGroup(
            authorId: _currentUserId,
            authorName: 'Tu Historia',
            authorPhotoUrl: null, // Dejamos que el widget inteligente lo busque
            stories: [],
            isOwnStory: true,
          ));
        }
        
        if (storyGroups.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<StoryItem> flattenedList = storyGroups
            .expand((group) => group.stories)
            .toList();

        return SizedBox(
          height: 100, // Le di un pelín más de altura para que no se corte el texto
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: storyGroups.length,
            itemBuilder: (context, index) {
              final group = storyGroups[index];
              return _StoryAvatar(
                group: group,
                onTap: () {
                  if (group.stories.isEmpty) {
                     // Aquí va tu navegación a StoryUploadScreen
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ir a subir historia...')),
                    );
                  } else {
                    final initialIndex = flattenedList.indexOf(group.stories.first);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (ctx, anim, secAnim) => StoryViewerScreen(
                          stories: flattenedList,
                          initialIndex: initialIndex.clamp(0, flattenedList.length - 1),
                        ),
                        transitionsBuilder: (ctx, anim, secAnim, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------
// WIDGET INTELIGENTE REFACTORIZADO
// -----------------------------------------------------------

class _StoryAvatar extends StatefulWidget {
  final StoryGroup group;
  final VoidCallback onTap;
  
  const _StoryAvatar({required this.group, required this.onTap});

  @override
  State<_StoryAvatar> createState() => _StoryAvatarState();
}

class _StoryAvatarState extends State<_StoryAvatar> {
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    if (widget.group.isOwnStory) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.group.authorId)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si es MI historia (o mi botón de agregar), busco la foto fresca en Firestore
    // para evitar que salga la "M" o una foto vieja.
    if (widget.group.isOwnStory) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          String? realPhotoUrl;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            // Asegúrate que el campo sea 'photoUrl' en tu colección users
            realPhotoUrl = data?['photoUrl']; 
          }
          // Si no cargó todavía, usa lo que venía en el grupo (fallback)
          realPhotoUrl ??= widget.group.authorPhotoUrl;
          
          return _buildAvatarUI(context, realPhotoUrl);
        },
      );
    }

    // Para otros usuarios, usamos lo que viene en la historia (para no leer tanto la BD)
    return _buildAvatarUI(context, widget.group.authorPhotoUrl);
  }

  Widget _buildAvatarUI(BuildContext context, String? photoUrl) {
    final accent = Theme.of(context).colorScheme.primary;
    final bool hasStories = widget.group.stories.isNotEmpty;
    // Si es "Tu historia" vacía, mostramos "Tu Historia", si no el nombre
    final displayName = (widget.group.isOwnStory && !hasStories) ? 'Tu Historia' : widget.group.authorName;

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: hasStories 
                  ? Border.all(color: accent, width: 2.0)
                  : Border.all(color: Colors.grey[700]!, width: 1.0),
              ),
              // Usamos ClipOval + Image.network para mejor control que CircleAvatar
              child: SizedBox(
                width: 56, // Equivalente a radius 28 * 2
                height: 56,
                child: ClipOval(
                  child: _buildImageContent(photoUrl, hasStories),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70, // Limitamos el ancho del texto
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.group.isOwnStory ? Colors.white : Colors.white70, 
                  fontSize: 11,
                  fontWeight: widget.group.isOwnStory ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(String? url, bool hasStories) {
    // 1. Caso especial: Mi historia vacía -> Mostrar símbolo +
    if (widget.group.isOwnStory && !hasStories) {
      // Si hay URL, la mostramos con un iconito de + superpuesto? 
      // Por simplicidad, si hay foto la mostramos, si no, ícono.
      // Pero normalmente el "Agregar" muestra la foto del usuario con un badge.
      // Aquí hacemos: Si hay foto -> Foto. Si no -> Icono Persona.
      if (url != null && url.isNotEmpty) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stack) => Image.asset(
                'assets/images/usuario.png',
                fit: BoxFit.cover,
              ),
            ),
            // Opcional: un pequeño overlay de "+"
            Container(
              color: Colors.black26,
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            )
          ],
        );
      } else {
        return Container(
          color: Colors.grey[800],
          child: const Icon(Icons.add, color: Colors.white),
        );
      }
    }

    // 2. Caso normal: Mostrar foto
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Si falla la carga de la imagen, mostramos usuario genérico
          return Image.asset('assets/images/usuario.png', fit: BoxFit.cover);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(child: SizedBox(width:10, height:10, child: CircularProgressIndicator(strokeWidth: 1))),
          );
        },
      );
    }

    // 3. Fallback final si no hay URL
    return Image.asset('assets/images/usuario.png', fit: BoxFit.cover);
  }
}