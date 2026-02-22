import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

// Ajustá la ruta si hace falta
import '../muro/reaction_viewers_row.dart'; 

class PostCardGeneral extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference postReference;

  final void Function(String emoji) onReact;
  final VoidCallback onCommentTap;
  final Future<void> Function()? onDelete; 
  final void Function(String placeId, String placeName) onPlaceTap;

  final void Function(String userId, String displayName, String photoUrl)?
      onUserTap;
  
  final bool isFeatured;
  final Future<void> Function()? onToggleFeatured; 
  final VoidCallback? onMoreTap;

  const PostCardGeneral({
    super.key,
    required this.data,
    required this.postReference,
    required this.onReact,
    required this.onCommentTap,
    required this.onDelete,
    required this.onPlaceTap,
    this.onUserTap,
    this.isFeatured = false, 
    this.onToggleFeatured,   
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final authorId = (data['authorId'] ?? '') as String;
    final authorName = (data['authorName'] ?? 'Usuario') as String;
    final authorPhotoUrl = (data['authorPhotoUrl'] ??
            data['authorPhotoURL'] ??
            data['imageUrl'] ??
            '') as String;

    final comentario = (data['comentario'] ?? data['texto'] ?? '') as String;
    final imageUrl = (data['imageUrl'] ?? '') as String;

    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final DateTime fecha = ts != null ? ts.toDate() : DateTime.now();

    final placeId = (data['placeId'] ?? '') as String;
    final placeName = (data['placeName'] ?? 'Comunidad BarApp') as String;

    final Map<String, dynamic> reaccionesMap =
        Map<String, dynamic>.from(data['reacciones'] ?? {});

    final Map<String, dynamic> reaccionesUsuariosRaw =
        Map<String, dynamic>.from(data['reaccionesUsuarios'] ?? {});

    const emojisDisponibles = ['🔥', '😍', '🍻', '😎'];

    String? myEmoji;
    if (currentUser != null) {
      final uid = currentUser.uid;
      reaccionesUsuariosRaw.forEach((emoji, lista) {
        final l = List<String>.from(lista ?? const []);
        if (l.contains(uid)) {
          myEmoji = emoji;
        }
      });
    }

    String timeAgo(DateTime date) {
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Hace un momento';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      if (diff.inDays == 1) return 'Ayer';
      return '${date.day}/${date.month}/${date.year}';
    }

    // Estilos
    final Color borderColor = isFeatured ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.05);
    final double borderWidth = isFeatured ? 1.5 : 1.0;
    final Color shadowColor = isFeatured ? Colors.amber.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.6);

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          elevation: isFeatured ? 10 : 6,
          shadowColor: shadowColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (onUserTap != null && authorId.isNotEmpty) {
                          onUserTap!(authorId, authorName, authorPhotoUrl);
                        }
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1A1A1A),
                        backgroundImage: authorPhotoUrl.isNotEmpty 
                            ? CachedNetworkImageProvider(authorPhotoUrl) 
                            : null,
                        child: authorPhotoUrl.isEmpty
                            ? Text(
                                authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isFeatured) 
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified, color: Color(0xFFFFD700), size: 14),
                                )
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (placeId.isNotEmpty)
                                GestureDetector(
                                  onTap: () => onPlaceTap(placeId, placeName),
                                  child: Text(
                                    placeName,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (placeId.isNotEmpty)
                                const Text(' · ', style: TextStyle(color: Colors.white38)),
                              Text(
                                timeAgo(fecha),
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                      onPressed: onMoreTap,
                    ),
                  ],
                ),
              ),

              // TEXTO
              if (comentario.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    comentario,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

              // IMAGEN
              if (imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white24),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
                                    ),
                                  ),
                                  fadeInDuration: const Duration(milliseconds: 300),
                                ),
                              ),
                              Positioned(
                                top: 40, right: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.black12,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.65,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.fitWidth,
                            // Optimizar memoria
                            memCacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
                            placeholder: (context, url) => Container(
                              height: 250,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                            ),
                            errorWidget: (context, url, error) => Container(
                               height: 250,
                               alignment: Alignment.center,
                               decoration: BoxDecoration(
                                 color: Colors.grey[900],
                                 borderRadius: BorderRadius.circular(18),
                               ),
                               child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                            ),
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // REACCIONES MEJORADAS CON ANIMACIONES
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    for (final emoji in emojisDisponibles)
                      _ReactionButton(
                        emoji: emoji,
                        count: reaccionesMap[emoji] ?? 0,
                        isSelected: myEmoji == emoji,
                        onTap: () => onReact(emoji),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onCommentTap,
                      child: Row(
                        children: const [
                          Icon(Icons.mode_comment_outlined, color: Colors.white70, size: 18),
                          SizedBox(width: 4),
                          Text('Comentar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------- QUIÉN REACCIONÓ (BLINDADO) ----------------
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                child: ReactionViewersRowGeneral(
                  postReference: postReference,
                  onUserTap: (userId, displayName, photoUrl) {
                    if (onUserTap != null) onUserTap!(userId, displayName, photoUrl);
                  },
                ),
              ),
            ],
          ),
        ),
        
        // ETIQUETA DESTACADO
        if (isFeatured)
          Positioned(
            top: 0,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))
                ]
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, size: 12, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    "DESTACADO", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget moderno para botones de reacción con animaciones
class _ReactionButton extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar cuando cambia el estado de selección
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isSelected ? 10 : 8,
                  vertical: widget.isSelected ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  // Diseño premium para emoji seleccionado
                  gradient: widget.isSelected
                      ? LinearGradient(
                          colors: [
                            Colors.orangeAccent.withValues(alpha: 0.3),
                            Colors.orangeAccent.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  // Borde premium con sombra para seleccionado
                  border: widget.isSelected
                      ? Border.all(
                          color: Colors.orangeAccent,
                          width: 1.5,
                        )
                      : null,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.emoji,
                      style: TextStyle(
                        fontSize: widget.isSelected ? 18 : 16,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (widget.count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? Colors.orangeAccent.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.count.toString(),
                          style: TextStyle(
                            color: widget.isSelected
                                ? Colors.orangeAccent
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}