import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter

class EventsEdgeButtonLeft extends StatefulWidget {
  final VoidCallback onTap;

  const EventsEdgeButtonLeft({super.key, required this.onTap});

  @override
  State<EventsEdgeButtonLeft> createState() => _EventsEdgeButtonLeftState();
}

class _EventsEdgeButtonLeftState extends State<EventsEdgeButtonLeft>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _offsetAnimation;

  // Definimos el color Violeta/Fucsia
  final Color _brandColor = Colors.purpleAccent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );

    _offsetAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.horizontal(right: Radius.circular(24));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value, 0),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              // Contenedor EXTERNO: Sombra/Glow violeta
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: _brandColor.withValues(alpha: 0.5), // Glow violeta
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                // ClipRRect: Recorte del vidrio
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        // Fondo negro semitransparente
                        color: Colors.black.withValues(alpha: 0.6), 
                        borderRadius: borderRadius,
                        // Borde Neon Violeta
                        border: Border.all(
                          color: _brandColor.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'Promos/Shows',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _brandColor, // Texto violeta neon
                            letterSpacing: 1.2,
                            shadows: [
                               Shadow(color: _brandColor.withValues(alpha: 0.8), blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}