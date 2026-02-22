import 'package:flutter/material.dart';
import 'package:barapp/models/place.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';
import 'package:barapp/ui/home/widgets/vertical_place_carousel.dart';

/// Widget que muestra la lista de lugares filtrados y ordenados
/// 
/// Maneja el filtrado por búsqueda y estado abierto/cerrado,
/// y el ordenamiento por popularidad o distancia
class HomePlacesList extends StatelessWidget {
  final List<Place> places;
  final List<String> followingIds;
  final String searchQuery;
  final String sortBy; // 'popular' o 'distance'
  final bool onlyOpen; // true o false
  final double? userLat;
  final double? userLng;
  final bool isLoading;
  final bool Function(Place place) isVenueOpen;
  final Future<void> Function(Place place, bool isFollowing) onFollowToggle;

  const HomePlacesList({
    super.key,
    required this.places,
    required this.followingIds,
    required this.searchQuery,
    required this.sortBy,
    required this.onlyOpen,
    required this.userLat,
    required this.userLng,
    required this.isLoading,
    required this.isVenueOpen,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. FILTRADO (Búsqueda + Abierto Ahora)
    final q = searchQuery.trim().toLowerCase();

    List<Place> filtered = places.where((p) {
      // Filtro Texto
      bool matchesSearch = true;
      if (q.isNotEmpty) {
        matchesSearch =
            p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q);
      }

      // Filtro Abierto
      bool matchesOpen = true;
      if (onlyOpen) {
        matchesOpen = isVenueOpen(p);
      }

      return matchesSearch && matchesOpen;
    }).toList();

    // 2. ORDENAMIENTO (Popularidad vs Distancia)
    // Hacemos una COPIA para no desordenar la lista maestra `places`
    filtered = List.from(filtered);

    if (sortBy == 'distance' && userLat != null) {
      filtered.sort((a, b) {
        double distA = a.distance ?? 999999;
        double distB = b.distance ?? 999999;
        return distA.compareTo(distB);
      });
    } else {
      // ORDEN POR POPULARIDAD (Por defecto)
      // Tratamos los nulls como 0 para que no explote ni oculte nada
      filtered.sort((a, b) {
        int followersA = a.followersCount ?? 0;
        int followersB = b.followersCount ?? 0;
        return followersB.compareTo(followersA); // De mayor a menor
      });
    }

    // 3. ESTADOS VACÍOS
    if (filtered.isEmpty && !isLoading) {
      if (onlyOpen) {
        return const Center(
          child: Text(
            "No hay bares abiertos ahora 😴",
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      return const Center(
        child: Text(
          "No se encontraron bares",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // 4. LISTA DE LUGARES
    return VerticalPlaceCarousel(
      places: filtered,
      followingIds: followingIds,
      // Pasamos la función de follow que viene del Mixin
      onFollowToggle: onFollowToggle,
      // Pasamos la navegación al detalle
      onTap: (place) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(placeId: place.id),
          ),
        );
      },
    );
  }
}
