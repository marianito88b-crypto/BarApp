import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Para permisos y ubicación

import '../../models/categories.dart';
import '../../models/place.dart';
import '../../theme.dart';
import '../place/place_detail_screen.dart';


class CategoryListScreen extends StatefulWidget {
  final Category category;
  const CategoryListScreen({super.key, required this.category});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  
  Position? _userPosition; 

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); 
  }

  // Función para obtener los permisos y la ubicación
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;
    
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    
    // Solo actualizamos el estado con la posición
    if (mounted) {
      setState(() {
        _userPosition = position;
      });
    }
  }

  // ELIMINADA: La primera función _getDistanceText(Place place) que estaba aquí
  // ya no es necesaria porque la lógica se movió al StreamBuilder.

 @override
  Widget build(BuildContext context) {
    final categoryString = widget.category.name;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('categories', arrayContains: categoryString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar lugares.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final places = snapshot.data!.docs
            .map((doc) => Place.fromFirestore(doc))
            .toList();

        // Si ya tenemos la posición del usuario, calculamos distancias
        if (_userPosition != null) {
          for (final p in places) {
            // coords válidas
            final hasCoords = p.hasValidCoords && p.lat.isFinite && p.lng.isFinite;

            if (hasCoords) {
              final meters = Geolocator.distanceBetween(
                _userPosition!.latitude,
                _userPosition!.longitude,
                p.lat,
                p.lng,
              );

              // si Geolocator devolviera algo raro (no debería), lo filtramos
              p.distance = meters.isFinite ? (meters / 1000.0) : null;
            } else {
              p.distance = null; // lugar sin coords → sin distancia
            }
          }

          // Orden: los que tienen distancia primero, luego los que no.
          places.sort((a, b) {
            final da = a.distance ?? double.infinity;
            final db = b.distance ?? double.infinity;
            return da.compareTo(db);
          });
        }

        // Helper para mostrar distancia en la UI (usa el place.distance calculado)
        // Esta función solo existe dentro de este 'builder'
        String getDistanceText(Place place) {
          final d = place.distance;
          if (d == null || !d.isFinite) return '... km';
          return '${d.toStringAsFixed(1)} km';
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final place = places[i];
            final accent = colorForCategory(widget.category);

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // ¡CORREGIDO!
                  // Tu PlaceDetailScreen espera un 'placeId' (String),
                  // no el objeto 'place' completo.
                  builder: (_) => PlaceDetailScreen(
                    placeId: place.id,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: .35)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconForCategory(widget.category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•',
                                  style: TextStyle(color: Colors.white70)),
                              const SizedBox(width: 8),
                              // Esta llamada usa la función _getDistanceText de adentro del builder
                              Text(getDistanceText(place),
                                  style:
                                  const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}