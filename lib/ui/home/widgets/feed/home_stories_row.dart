import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barapp/models/story_item.dart';
import 'add_story_button.dart';
import 'story_circle_widget.dart';

/// Grupo de historias por usuario (similar a Instagram)
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

/// Fila horizontal de historias agrupadas por usuario
/// 
/// Muestra el botón de agregar historia y las historias agrupadas por usuario
/// (similar a Instagram - un círculo por usuario con todas sus historias)
class HomeStoriesRow extends StatefulWidget {
  final Color accent;
  final VoidCallback onAdd;
  final void Function(StoryItem story, int index, List<StoryItem> allStories)
      onTapStory;

  const HomeStoriesRow({
    super.key,
    required this.accent,
    required this.onAdd,
    required this.onTapStory,
  });

  @override
  State<HomeStoriesRow> createState() => _HomeStoriesRowState();
}

class _HomeStoriesRowState extends State<HomeStoriesRow> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _storiesStream;

  @override
  void initState() {
    super.initState();
    _storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _storiesStream,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('Error en Stream de Historias: ${snap.error}');
          return const SizedBox.shrink();
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 84,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final now = DateTime.now();

        // Obtener todas las historias válidas
        var allItems = (snap.data?.docs ?? [])
            .map((d) => StoryItem.fromFirestore(d))
            .where((story) {
              try {
                final exp = story.expiresAt.toDate();
                return exp.isAfter(now);
              } catch (_) {
                return false;
              }
            })
            .toList();

        // Agrupar por autor
        final Map<String, List<StoryItem>> storiesByAuthor = {};
        for (final item in allItems) {
          (storiesByAuthor[item.authorId] ??= []).add(item);
        }

        // Crear grupos de historias
        final List<StoryGroup> storyGroups = [];
        StoryGroup? myStoryGroup;

        storiesByAuthor.forEach((authorId, stories) {
          if (stories.isEmpty) return;
          
          // Ordenar historias del mismo autor por fecha (más reciente primero)
          stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          final firstStory = stories.first;
          final group = StoryGroup(
            authorId: authorId,
            authorName: firstStory.authorName,
            authorPhotoUrl: firstStory.authorPhotoUrl,
            stories: stories,
            isOwnStory: authorId == currentUserId,
          );

          if (group.isOwnStory) {
            myStoryGroup = group;
          } else {
            storyGroups.add(group);
          }
        });

        // Ordenar grupos: destacados primero, luego por fecha de última historia
        storyGroups.sort((a, b) {
          final aHasFeatured = a.stories.any((s) => s.isFeatured);
          final bHasFeatured = b.stories.any((s) => s.isFeatured);
          if (aHasFeatured && !bHasFeatured) return -1;
          if (!aHasFeatured && bHasFeatured) return 1;
          // Si ambos tienen o no tienen destacadas, ordenar por fecha de última historia
          final aLastStory = a.stories.first.createdAt;
          final bLastStory = b.stories.first.createdAt;
          return bLastStory.compareTo(aLastStory);
        });

        // Insertar mi historia al principio si existe
        bool hasMyStoryGroup = false;
        if (myStoryGroup != null) {
          storyGroups.insert(0, myStoryGroup!);
          hasMyStoryGroup = true;
        }

        // Crear lista plana de todas las historias para el viewer
        final List<StoryItem> flattenedStories = storyGroups
            .expand((group) => group.stories)
            .toList();

        // Determinar si debemos mostrar el botón de agregar al principio
        // Solo lo mostramos si el usuario actual NO tiene historias (no está en ningún grupo)
        final bool showAddButtonFirst = currentUserId != null && !hasMyStoryGroup;

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
          physics: const BouncingScrollPhysics(),
          itemCount: storyGroups.length + (showAddButtonFirst ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            // Primer item: botón de agregar (solo si el usuario no tiene historias)
            if (showAddButtonFirst && i == 0) {
              return AddStoryButton(onTap: widget.onAdd);
            }

            // Ajustar índice si hay botón de agregar al principio
            final groupIndex = showAddButtonFirst ? i - 1 : i;
            final group = storyGroups[groupIndex];

            // Obtener la primera historia del grupo para mostrar
            final firstStory = group.stories.first;
            
            // Encontrar el índice de esta historia en la lista plana
            final storyIndex = flattenedStories.indexOf(firstStory);
            
            // Determinar color del borde: destacada o normal
            final hasFeatured = group.stories.any((s) => s.isFeatured);
            final borderColor = hasFeatured ? Colors.amber : widget.accent;

            return StoryCircleWidget(
              story: firstStory,
              borderColor: borderColor,
              isOwnStory: group.isOwnStory,
              onAddStory: group.isOwnStory ? widget.onAdd : null,
              onTap: () {
                if (storyIndex >= 0 && storyIndex < flattenedStories.length) {
                  widget.onTapStory(firstStory, storyIndex, flattenedStories);
                }
              },
            );
          },
        );
      },
    );
  }
}
