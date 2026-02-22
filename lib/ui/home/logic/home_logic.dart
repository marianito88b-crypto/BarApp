import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:barapp/models/place.dart';
import 'package:barapp/services/follow_service.dart';
import 'package:barapp/utils/venue_utils.dart';

/// Mixin que centraliza la lógica de datos y filtrado del feed de inicio
/// 
/// Maneja la carga de lugares, ubicación, seguimiento de usuarios,
/// filtrado por búsqueda y estado abierto/cerrado
mixin HomeLogicMixin<T extends StatefulWidget> on State<T> {
  // --- Estado de datos ---
  final List<Place> _places = [];
  List<String> _followingIds = [];
  final Map<String, Map<String, dynamic>> _placeDataCache = {};
  StreamSubscription? _userSub;
  double? _userLat;
  double? _userLng;
  bool _isLoading = false;

  // --- Estado de búsqueda y filtros ---
  String _searchQuery = '';
  Timer? _searchDebounce;

  // --- Getters públicos ---
  List<Place> get places => _places;
  List<String> get followingIds => _followingIds;
  Map<String, Map<String, dynamic>> get placeDataCache => _placeDataCache;
  double? get userLat => _userLat;
  double? get userLng => _userLng;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Inicializa la lógica del feed
  /// 
  /// Debe llamarse en initState del State que usa este Mixin
  void initHomeLogic() {
    _loadLocation();
    _subscribeToUserFollowing();
    _loadAllPlaces();
  }

  /// Limpia recursos del Mixin
  /// 
  /// Debe llamarse en dispose del State que usa este Mixin
  void disposeHomeLogic() {
    _searchDebounce?.cancel();
    _userSub?.cancel();
  }

  /// Actualiza la query de búsqueda con debounce para evitar saturar Firebase
  /// 
  /// El debounce espera 500ms antes de actualizar la query
  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  /// Carga todos los lugares desde Firestore
  Future<void> _loadAllPlaces() async {
    setState(() => _isLoading = true);

    try {
      // 1. Pedimos TODOS los bares (Límite alto por seguridad)
      // SIN orderBy para que no discrimine a los que les faltan campos
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .limit(200)
          .get();

      final allPlaces = snap.docs
          // 🔥 FILTRO NUEVO: Ocultar bares de prueba/mantenimiento
          .where((doc) {
            final data = doc.data();
            // Si isHidden es true, lo sacamos. Si no existe (null) o es false, lo dejamos pasar.
            return data['isHidden'] != true;
          })
          // Mapeo normal (igual que antes)
          .map((d) {
            final placeData = d.data();
            final p = Place.fromMap(id: d.id, data: placeData);

            // Guardamos los datos originales de Firestore para usar en el filtro
            _placeDataCache[d.id] = placeData;

            // Calculamos distancia si tenemos GPS
            if (_userLat != null && _userLng != null && p.hasValidCoords) {
              p.distance = Geolocator.distanceBetween(
                _userLat!,
                _userLng!,
                p.lat,
                p.lng,
              );
            }
            return p;
          }).toList();

      if (mounted) {
        setState(() {
          _places.clear(); // Limpiamos por si acaso
          _places.addAll(allPlaces);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando bares: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Carga la ubicación del usuario usando Geolocator
  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() {
          _userLat = last.latitude;
          _userLng = last.longitude;
        });
      }
      // Actualizamos distancia en los bares ya cargados si llega ubicación tarde
      // (Opcional, para simplificar no lo re-calculo masivo aquí)
    } catch (_) {}
  }

  /// Suscribe al stream de seguimiento del usuario para actualizar contadores
  void _subscribeToUserFollowing() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null && data['followingBars'] != null) {
          // 1. Obtenemos la NUEVA lista que viene de Firebase
          final List<String> newFollowingIds =
              List<String>.from(data['followingBars']);

          setState(() {
            // 🔥 LA MAGIA: Sincronización Matemática
            // Recorremos los bares que tenemos en pantalla para ver si hay que ajustar contadores
            for (var place in _places) {
              // ¿Lo seguía antes? (Usamos la lista vieja _followingIds)
              bool wasFollowing = _followingIds.contains(place.id);

              // ¿Lo sigo ahora? (Usamos la lista nueva)
              bool isNowFollowing = newFollowingIds.contains(place.id);

              // CASO 1: Dejé de seguirlo (desde perfil o detalle)
              if (wasFollowing && !isNowFollowing) {
                // Le restamos 1 al contador visualmente
                if ((place.followersCount ?? 0) > 0) {
                  place.followersCount = (place.followersCount ?? 1) - 1;
                }
              }
              // CASO 2: Empecé a seguirlo (desde otro lado)
              else if (!wasFollowing && isNowFollowing) {
                // Le sumamos 1 al contador visualmente
                place.followersCount = (place.followersCount ?? 0) + 1;
              }
            }

            // 2. Finalmente actualizamos la lista maestra de IDs para los corazones
            _followingIds = newFollowingIds;
          });
        }
      }
    });
  }

  /// Convierte un Place a un Map con los campos necesarios para VenueUtils
  /// 
  /// Usa los datos originales de Firestore guardados en _placeDataCache si están disponibles,
  /// de lo contrario construye un mapa mínimo desde Place con valores por defecto.
  Map<String, dynamic> _placeToVenueData(Place place) {
    // Intentar obtener los datos originales de Firestore
    final cachedData = _placeDataCache[place.id];

    if (cachedData != null) {
      // Usar los datos completos de Firestore que incluyen aceptaPedidos, tieneDobleTurno, etc.
      return {
        'aceptaPedidos': cachedData['aceptaPedidos'] ?? true,
        'horarioApertura': cachedData['horarioApertura'] ?? place.openTime ?? '',
        'horarioCierre': cachedData['horarioCierre'] ?? place.closeTime ?? '',
        'tieneDobleTurno': cachedData['tieneDobleTurno'] ?? false,
        'horarioApertura2': cachedData['horarioApertura2'] ?? '',
        'horarioCierre2': cachedData['horarioCierre2'] ?? '',
      };
    }

    // Fallback: construir desde Place con valores por defecto
    return {
      'aceptaPedidos': true, // Por defecto asumimos que acepta pedidos si no hay info
      'horarioApertura': place.openTime ?? '',
      'horarioCierre': place.closeTime ?? '',
      'tieneDobleTurno': false, // Place no tiene info de doble turno, asumimos false
      'horarioApertura2': '',
      'horarioCierre2': '',
    };
  }

  /// Verifica si un local está abierto usando VenueUtils centralizado
  /// 
  /// Esta función reemplaza la lógica vieja y ahora usa la utilidad centralizada
  /// que maneja correctamente turnos partidos y cruces de medianoche
  bool isVenueOpen(Place place) {
    final venueData = _placeToVenueData(place);
    return VenueUtils.isVenueOpen(venueData);
  }

  /// Maneja el toggle de seguir/dejar de seguir un lugar con UI optimista
  /// 
  /// Actualiza la UI inmediatamente y luego sincroniza con Firebase.
  /// Si falla la sincronización, revierte los cambios.
  Future<void> handleFollow(Place place, bool isCurrentlyFollowing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. UI OPTIMISTA (Instantánea)
    // Calculamos el nuevo valor esperado
    final int optimisticCount =
        (place.followersCount ?? 0) + (isCurrentlyFollowing ? -1 : 1);

    setState(() {
      if (isCurrentlyFollowing) {
        _followingIds.remove(place.id);
      } else {
        _followingIds.add(place.id);
      }
      // 🔥 CLAVE: Actualizamos el objeto real en la lista
      place.followersCount = optimisticCount < 0 ? 0 : optimisticCount;
    });

    // 2. LLAMADA A FIREBASE (Usando el servicio mejorado)
    final int? resultIncrement = await FollowService.toggleFollow(
      placeId: place.id,
      isCurrentlyFollowing: isCurrentlyFollowing,
    );

    // 3. VERIFICACIÓN Y CORRECCIÓN (Rollback si falló)
    if (resultIncrement == null) {
      // Falló la red, revertimos cambios
      if (mounted) {
        setState(() {
          if (isCurrentlyFollowing) {
            _followingIds.add(place.id); // Lo devolvemos a la lista
            place.followersCount = (place.followersCount ?? 0) + 1;
          } else {
            _followingIds.remove(place.id); // Lo sacamos de nuevo
            place.followersCount = (place.followersCount ?? 1) - 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión")),
        );
      }
    }
  }
}
