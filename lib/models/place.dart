// lib/models/place.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'categories.dart';

/// Modelo robusto para locales (bares/restos/cafeterías/heladerías).
class Place {
  // -------- Persistidos ----------
  final String id;
  final String name;
  final String address;
 
  final double lat;
  final double lng;

  final List<String> imageUrls;          
  final Map<String, dynamic>? openingHours; 
  final String? phone;                   
  final String? website;                 
  final List<Category> categories; 
  final double? ratingAvg;               
  final int? ratingCount;                

  final DateTime? createdAt;             
  final DateTime? updatedAt;
  
  // 🔥 CAMPOS CLAVE PARA FILTROS Y UI
  final String? openTime;  // "20:00"
  final String? closeTime; // "04:00"             
  final List<String>? features; // Ej: ['Terraza', 'Wifi']
  final bool? isOpenNow;    
  final String? coverImageUrl;   
  
  // ⚠️ NO ES FINAL: Para poder actualizarlo visualmente al dar Like/Unlike
  int? followersCount;

  /// Si el local acepta canje de BarPoints
  final bool? aceptaBarpoints;
  /// Si el canje está disponible hoy (control del dueño para días de poco movimiento)
  final bool? barpointsDisponiblesHoy;

  // -------- Transiente (no persistido) ----------
  double? distance; 

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.categories,
    required this.lat,
    required this.lng,
    required this.imageUrls,
    this.coverImageUrl,
    this.openingHours,
    this.phone,
    this.website,
    this.ratingAvg,
    this.ratingCount,
    this.createdAt,
    this.updatedAt,
    this.distance,
    this.features,
    this.isOpenNow,
    this.followersCount,
    this.openTime,
    this.closeTime,
    this.aceptaBarpoints,
    this.barpointsDisponiblesHoy,
  });

  // ---------- Validaciones ----------
  bool get hasValidCoords {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  // ---------- Factories ----------
  factory Place.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Place.fromMap(id: doc.id, data: data);
  }

  factory Place.fromMap({required String id, required Map<String, dynamic> data}) {
    final _LatLng ll = _readLatLng(data);
    
    // Lectura robusta de followers
    final int followersCount = _asNullableInt(data['followersCount']) ?? 0;

    // 1) Lee array 'categories'
    List<String> rawCats;
    if (data['categories'] is List) {
      rawCats = List<String>.from((data['categories'] as List).map((e) => (e ?? '').toString()));
    } else if (data['category'] != null) {
      rawCats = [(data['category'] ?? '').toString()];
    } else {
      rawCats = const [];
    }

    // 2) Normaliza (quita acentos, minusculas)
    String normalizeCat(String s) {
      final lower = s.toLowerCase().trim();
      return lower
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');
    }

    final lowered = rawCats.map(normalizeCat).toList();

    // 3) Mapea a valores del enum
    String mapToKey(String s) {
      if (s.contains('restaur')) return 'restaurants';
      if (s.contains('cafe') || s.contains('cafeter')) return 'cafes';
      if (s.contains('cervec')) return 'cerveceria';
      if (s.contains('helad') || s.contains('ice')) return 'icecream';
      if (s.contains('pub')) return 'pub';
      if (s.contains('bar')) return 'bar';
      return 'todos';
    }

    final normalizedKeys = lowered.map(mapToKey).toSet().toList();
    if (normalizedKeys.isEmpty) normalizedKeys.add('todos');

    final parsedCategories = normalizedKeys.map((k) {
      try {
        return Category.values.firstWhere((e) => e.name == k);
      } catch (_) {
        return Category.todos;
      }
    }).toList();

    return Place(
      id: id,
      name: _asString(data['name'], fallback: 'Sin nombre'),
      address: _asString(data['address'], fallback: 'Dirección no disponible'),
      categories: parsedCategories,
      lat: ll.lat,
      lng: ll.lng,
      imageUrls: _readStringList(data['images']) ??
          _readStringList(data['imageUrls']) ??
          const [],
      coverImageUrl: _asNullableString(data['coverImageUrl']),
      openingHours: _readMap(data['openingHours']),
      phone: _asNullableString(data['phone']),
      website: _asNullableString(data['website']),
      ratingAvg: _asNullableDouble(data['ratingAvg']),
      ratingCount: _asNullableInt(data['ratingCount']),
      createdAt: _tsToDateTime(data['createdAt']),
      updatedAt: _tsToDateTime(data['updatedAt']),
      
      // ✅ FEATURES: Leemos 'features' o 'caracteristicas'
      features: _readStringList(data['features']) ?? _readStringList(data['caracteristicas']) ?? [],
      
      isOpenNow: data['isOpenNow'] as bool?,
      followersCount: followersCount,
      
      // 🔥 CORRECCIÓN CLÍNICA: Usamos _asNullableString para seguridad total
      openTime: _asNullableString(data['horarioApertura']),
      closeTime: _asNullableString(data['horarioCierre']),

      // BarPoints: si el local acepta canje
      aceptaBarpoints: data['aceptaBarpoints'] == true,
      barpointsDisponiblesHoy: data['barpointsDisponiblesHoy'] == true,
    );
  }

  // ---------- Serialización ----------
  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final categoryStrings = categories.map((c) => c.name).toList();
    return <String, dynamic>{
      'name': name,
      'address': address,
      'categories': categoryStrings,
      'lat': lat,
      'lng': lng,
      if (imageUrls.isNotEmpty) 'images': imageUrls,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl, // Agregado para consistencia
      if (openingHours != null) 'openingHours': openingHours,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (ratingAvg != null) 'ratingAvg': ratingAvg,
      if (ratingCount != null) 'ratingCount': ratingCount,
      
      // Features
      if (features != null && features!.isNotEmpty) 'features': features,
      
      // Followers y Horarios
      'followersCount': followersCount ?? 0,
      if (openTime != null) 'horarioApertura': openTime,
      if (closeTime != null) 'horarioCierre': closeTime,

      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ---------- copyWith ----------
  Place copyWith({
    String? id,
    String? name,
    String? address,
    List<Category>? categories,
    double? lat,
    double? lng,
    List<String>? imageUrls,
    Map<String, dynamic>? openingHours,
    String? phone,
    String? website,
    double? ratingAvg,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distance,
    List<String>? features,
    bool? isOpenNow,
    // Agregamos los faltantes al copyWith
    String? openTime,
    String? closeTime,
    int? followersCount,
    String? coverImageUrl,
    bool? aceptaBarpoints,
    bool? barpointsDisponiblesHoy,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      categories: categories ?? this.categories,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrls: imageUrls ?? this.imageUrls,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distance: distance ?? this.distance,
      features: features ?? this.features,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      followersCount: followersCount ?? this.followersCount,
      aceptaBarpoints: aceptaBarpoints ?? this.aceptaBarpoints,
      barpointsDisponiblesHoy: barpointsDisponiblesHoy ?? this.barpointsDisponiblesHoy,
    );
  }

  // ---------- Helpers estáticos (parseo robusto) ----------
  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double _toDouble(dynamic v, {double onNaN = double.nan}) {
    if (v == null) return onNaN;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v.replaceAll(',', '.'));
      return parsed ?? onNaN;
    }
    return onNaN;
  }

  static double? _asNullableDouble(dynamic v) {
    if (v == null) return null;
    final d = _toDouble(v, onNaN: double.nan);
    return d.isNaN ? null : d;
  }

  static int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      return p;
    }
    return null;
  }

  static DateTime? _tsToDateTime(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }

  static Map<String, dynamic>? _readMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    return null;
  }

  static List<String>? _readStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => e?.toString())
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    return null;
  }

  static _LatLng _readLatLng(Map<String, dynamic> data) {
    for (final key in const ['location', 'geopoint', 'coords']) {
      final v = data[key];
      if (v is GeoPoint) {
        return _LatLng(v.latitude, v.longitude);
      }
    }
    double lat = _toDouble(_readFirst(data, const ['lat', 'latitude', 'geo.lat']));
    double lng = _toDouble(_readFirst(data, const ['lng', 'lon', 'longitude', 'geo.lng']));
    return _LatLng(lat, lng);
  }

  static dynamic _readFirst(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      if (data.containsKey(k)) return data[k];
    }
    return null;
  }

  String distanceLabel({int fractionDigits = 1}) {
    final d = distance;
    if (d == null || !d.isFinite) return '... km';
    return '${d.toStringAsFixed(fractionDigits)} km';
  }

  static int compareByDistance(Place a, Place b) {
    final da = a.distance ?? double.infinity;
    final db = b.distance ?? double.infinity;
    return da.compareTo(db);
  }

  @override
  String toString() => 'Place($id, $name, feats=$features)';
}

class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}