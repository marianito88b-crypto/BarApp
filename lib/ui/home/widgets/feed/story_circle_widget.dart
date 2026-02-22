import 'package:flutter/material.dart';
import 'package:barapp/models/story_item.dart';

/// Widget circular que representa una historia individual
/// 
/// Muestra el avatar del autor con animación de pulso si la historia está destacada
class StoryCircleWidget extends StatefulWidget {
  final StoryItem story;
  final Color borderColor;
  final VoidCallback onTap;

  const StoryCircleWidget({
    super.key,
    required this.story,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<StoryCircleWidget> createState() => _StoryCircleWidgetState();
}

class _StoryCircleWidgetState extends State<StoryCircleWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (widget.story.isFeatured) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);

      // Bajamos el rango del resplandor para evitar overflows (de 8-18 a 5-12)
      _animation = Tween<double>(begin: 5.0, end: 12.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFFFD700);

    // Si no es destacada, círculo simple y más chico
    if (!widget.story.isFeatured) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: _buildAvatarContent(24), // Radio reducido
        ),
      );
    }

    // Versión destacada con pulso
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.all(4.0), // Margen para que el brillo respire
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.5),
                  blurRadius: _animation!.value,
                  spreadRadius: _animation!.value / 4,
                ),
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.25),
                  blurRadius: _animation!.value * 1.8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(color: goldColor, width: 2.0),
            ),
            child: _buildAvatarContent(24), // Radio reducido
          ),
        );
      },
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
