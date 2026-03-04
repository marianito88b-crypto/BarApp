import 'package:flutter/material.dart';
import 'package:barapp/models/story_item.dart';

/// Widget circular que representa una historia individual
///
/// Muestra el avatar del autor con animación de pulso si la historia está destacada.
/// Si es la historia del usuario actual, muestra overlay "+" y long-press con opciones.
class StoryCircleWidget extends StatefulWidget {
  final StoryItem story;
  final Color borderColor;
  final VoidCallback onTap;
  final bool isOwnStory;
  final VoidCallback? onAddStory;

  const StoryCircleWidget({
    super.key,
    required this.story,
    required this.borderColor,
    required this.onTap,
    this.isOwnStory = false,
    this.onAddStory,
  });

  @override
  State<StoryCircleWidget> createState() => _StoryCircleWidgetState();
}

class _StoryCircleWidgetState extends State<StoryCircleWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  void _initFeaturedAnimation() {
    if (_controller != null) return;
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 5.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  void _disposeFeaturedAnimation() {
    _controller?.dispose();
    _controller = null;
    _animation = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.story.isFeatured) _initFeaturedAnimation();
  }

  @override
  void didUpdateWidget(covariant StoryCircleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.story.isFeatured && !oldWidget.story.isFeatured) {
      _initFeaturedAnimation();
    } else if (!widget.story.isFeatured && oldWidget.story.isFeatured) {
      _disposeFeaturedAnimation();
    }
  }

  @override
  void dispose() {
    _disposeFeaturedAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFFFD700);

    final onLongPress = widget.isOwnStory && widget.onAddStory != null
        ? () => _showOwnStoryOptions(context)
        : null;

    // Si no es destacada, círculo simple y más chico
    if (!widget.story.isFeatured) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.borderColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: _buildAvatarContent(24),
            ),
            if (widget.isOwnStory) _buildAddOverlay(context),
          ],
        ),
      );
    }

    // Versión destacada con pulso
    // Fallback: si _animation es null (p. ej. didUpdateWidget aún no inicializó), mostramos versión estática
    final anim = _animation;
    if (anim == null) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: goldColor, width: 2.0),
              ),
              child: _buildAvatarContent(24),
            ),
            if (widget.isOwnStory) _buildAddOverlay(context),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return GestureDetector(
          onTap: widget.onTap,
          onLongPress: onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.all(4.0),
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                    boxShadow: [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.5),
                      blurRadius: anim.value,
                      spreadRadius: anim.value / 4,
                    ),
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.25),
                      blurRadius: anim.value * 1.8,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(color: goldColor, width: 2.0),
                ),
                child: _buildAvatarContent(24),
              ),
              if (widget.isOwnStory) _buildAddOverlay(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOverlay(BuildContext context) {
    return Positioned(
      bottom: -2,
      right: -2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF121212), width: 2),
        ),
        child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
      ),
    );
  }

  void _showOwnStoryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_rounded, color: Colors.white70),
                title: const Text('Ver historias', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70),
                title: const Text('Subir nueva historia', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddStory!();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[900],
      backgroundImage: (widget.story.authorPhotoUrl != null &&
              widget.story.authorPhotoUrl!.isNotEmpty)
          ? NetworkImage(widget.story.authorPhotoUrl!)
          : null,
      child: (widget.story.authorPhotoUrl == null ||
              widget.story.authorPhotoUrl!.isEmpty)
          ? Text(
              widget.story.authorName.isNotEmpty
                  ? widget.story.authorName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.6,
              ),
            )
          : null,
    );
  }
}
