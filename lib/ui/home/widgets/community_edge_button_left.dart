import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter

class CommunityEdgeButtonLeft extends StatefulWidget {
  final VoidCallback onTap;

  const CommunityEdgeButtonLeft({super.key, required this.onTap});

  @override
  State<CommunityEdgeButtonLeft> createState() => _CommunityEdgeButtonLeftState();
}

class _CommunityEdgeButtonLeftState extends State<CommunityEdgeButtonLeft>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _offsetAnimation;

  // Definimos el color Naranja Coral aquí para usarlo en bordes y texto
  final Color _brandColor = const Color(0xFFFF7F50);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.10).animate( // Bajé un poco la escala para que no vibre tanto
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
              // Contenedor EXTERNO: Solo dibuja la sombra (Glow)
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: _brandColor.withValues(alpha: 0.5), // Resplandor naranja
                      blurRadius: 15, // Bien difuminado
                      spreadRadius: 1,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                // ClipRRect: Recorta el efecto vidrio (Blur)
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto Glass
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        // Fondo oscuro semitransparente
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: borderRadius,
                        // Borde de color sólido (Estilo Neon)
                        border: Border.all(
                          color: _brandColor.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'Muro social',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Ajusté un poco para que entre bien
                            color: _brandColor, // Texto naranja neon sobre negro
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