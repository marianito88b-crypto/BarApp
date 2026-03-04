import 'package:flutter/material.dart';
import 'package:barapp/models/place.dart';
import 'dart:ui'; 

class PlaceCard extends StatelessWidget {
  final Place place;
  final ImageProvider imageProvider;
  final VoidCallback? onTap;
  final bool isFollowing;
  final VoidCallback onFollowTap;
  final int followersCount;
  final bool isFocused; 

  const PlaceCard({
    super.key,
    required this.place,
    required this.imageProvider,
    required this.isFollowing,
    required this.followersCount,
    required this.onFollowTap,
    this.onTap,
    this.isFocused = false, 
  });

  @override
  Widget build(BuildContext context) {
    const customShape = BorderRadius.only(
      topLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    );

    final String distanceText = _formatDistance(place.distance);
    final bool hasDistance = distanceText.isNotEmpty;
    // < 1 km: persona caminando (cercano); >= 1 km: icono de ubicación (lejos)
    final bool isNear = place.distance != null && place.distance! < 1000;
    const brandColor = Color(0xFFFF7F50);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: customShape,
        // 🔥 1. BORDE MÁS DEFINIDO
        border: isFocused 
            ? Border.all(color: brandColor.withValues(alpha: 0.8), width: 1.2) 
            : Border.all(color: Colors.transparent, width: 0),
        boxShadow: [
          isFocused 
              ? BoxShadow( 
                  // 🔥 2. RESPLANDOR MUCHO MÁS INTENSO
                  color: brandColor.withValues(alpha: 0.65), // Más fuerte (antes 0.3)
                  blurRadius: 45, // Luz llega más lejos (antes 30)
                  spreadRadius: 0, // Quitamos el negativo para que asome más (antes -5)
                  offset: const Offset(0, 0),
                )
              : BoxShadow( 
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(4, 8),
                ),
        ],
      ),
      child: ClipRRect(
        borderRadius: customShape,
        child: Stack(
          children: [
            // 1. IMAGEN DE FONDO
            Positioned.fill(
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF1E1E1E)),
              ),
            ),

            // 2. DETECTOR DE TOQUE
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  highlightColor: brandColor.withValues(alpha: 0.1),
                  splashColor: brandColor.withValues(alpha: 0.2),
                ),
              ),
            ),

            // 2b. SELLO BARPOINT (si el local acepta)
            if (place.aceptaBarpoints == true)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.loyalty_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'BarPoint',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. SEGUIDORES
            Positioned(
              top: 12, right: 12,
              child: GestureDetector(
                onTap: onFollowTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing ? Icons.favorite : Icons.favorite_border,
                            color: isFollowing ? Colors.redAccent : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$followersCount',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. PANEL INFERIOR (GLASS)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          place.name.isNotEmpty ? place.name : 'Sin nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: isFocused 
                                ? [Shadow(color: brandColor.withValues(alpha: 0.8), blurRadius: 12)] // Texto brilla un poco más también
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 18),
                            const SizedBox(width: 4),
                            Text((place.ratingAvg ?? 0).toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(' (${place.ratingCount ?? 0})',
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const Spacer(),
                            if (hasDistance)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  // Verde suave si está cerca, blanco translúcido si está lejos
                                  color: isNear
                                      ? Colors.green.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      // Persona caminando = cerca (<1km), pin = lejos
                                      isNear
                                          ? Icons.directions_walk_rounded
                                          : Icons.near_me_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(distanceText,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. MÁSCARA DE OSCURECIMIENTO CON IGNORE POINTER
            if (!isFocused)
              Positioned.fill(
                child: IgnorePointer( 
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: Colors.black.withValues(alpha: 0.5), 
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters < 0) return '';
    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${(distanceMeters / 10).round() * 10} m';
    }
  }
}