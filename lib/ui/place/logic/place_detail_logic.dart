import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';
import 'package:barapp/models/place.dart';
import '../widgets/detail/registration_dialog.dart';

/// Mixin que contiene la lógica de negocio para PlaceDetailScreen
/// 
/// Maneja geolocalización, calificaciones, utilidades y efectos visuales
mixin PlaceDetailLogicMixin<T extends StatefulWidget> on State<T> {
  // ===========================================================================
  // 🎊 EFECTOS VISUALES
  // ===========================================================================
  late ConfettiController confettiController;

  /// Inicializa el ConfettiController
  void initConfettiController() {
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  /// Libera recursos del ConfettiController
  void disposeConfettiController() {
    confettiController.dispose();
  }

  // ===========================================================================
  // 📍 GEOLOCALIZACIÓN OPTIMIZADA
  // ===========================================================================
  
  /// Calcula la distancia al lugar usando GPS optimizado
  /// 
  /// Usa la última posición conocida primero para respuesta instantánea
  Future<void> checkAndCalculateDistance(
    Place place,
    void Function(Position? position, double distance) onDistanceCalculated,
  ) async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      if (mounted) {
        onDistanceCalculated(null, double.infinity);
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        onDistanceCalculated(null, double.infinity);
      }
      return;
    }

    if (!place.hasValidCoords) {
      if (mounted) {
        onDistanceCalculated(null, double.infinity);
      }
      return;
    }

    // 🚀 OPTIMIZACIÓN: Usar última conocida primero (Instantáneo)
    Position? position = await Geolocator.getLastKnownPosition();

    // Si no hay última conocida, pedimos la actual (puede tardar un poco)
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ),
    );

    final distGeolocator = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.lat,
      place.lng,
    );

    if (mounted) {
      onDistanceCalculated(
        position,
        distGeolocator.isNaN ? double.infinity : distGeolocator,
      );
    }
  }

  // ===========================================================================
  // ⭐ CALIFICACIONES
  // ===========================================================================

  /// Guarda una calificación del usuario para un lugar
  Future<void> submitRating(Place place, int rating, String comment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Iniciá sesión para calificar.')),
          );
        }
        return;
      }

      final placeRef = FirebaseFirestore.instance
          .collection('places')
          .doc(place.id);
      final ratingDoc = placeRef.collection('ratings').doc(user.uid);

      await ratingDoc.set({
        'rating': rating,
        'comment': comment.isEmpty ? null : comment,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Usuario',
        'userAvatarUrl': user.photoURL,
        'placeId': place.id,
        'placeName': place.name,
      }, SetOptions(merge: true));

      // Actualizar promedio
      final allRatingsSnapshot = await placeRef.collection('ratings').get();
      final allRatingsDocs = allRatingsSnapshot.docs;
      final int newRatingCount = allRatingsDocs.length;

      if (newRatingCount == 0) {
        await placeRef.update({'ratingAvg': 0.0, 'ratingCount': 0});
      } else {
        double totalRating = allRatingsDocs.fold(
          0.0,
          (acc, doc) => acc + (doc.data()['rating'] as num? ?? 0).toDouble(),
        );
        final double newRatingAvg = totalRating / newRatingCount;
        await placeRef.update({
          'ratingAvg': newRatingAvg,
          'ratingCount': newRatingCount,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tu calificación fue guardada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar calificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la calificación.')),
        );
      }
    }
  }

  /// Muestra el diálogo para calificar un lugar
  Future<void> showRatingDialog(Place place) async {
    int selectedRating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Calificar Restaurante',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Qué tal fue tu experiencia en ${place.name}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => selectedRating = starValue);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Añade un comentario (Opcional)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    submitRating(
                      place,
                      selectedRating,
                      commentController.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 🔗 UTILIDADES
  // ===========================================================================

  /// Formatea la distancia en metros a un string legible
  /// 
  /// Ejemplos:
  /// - 500 m -> "500 m"
  /// - 1500 m -> "1.5 km"
  /// - 10000 m -> "10 km"
  String formatDistanceMeters(double meters) {
    if (!meters.isFinite) return '…';
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// Abre una URL en el navegador o aplicación externa
  Future<void> launchSocialUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  // ===========================================================================
  // 📱 REGISTRO DE INVITADOS
  // ===========================================================================

  /// Muestra el diálogo de registro para invitados
  void showRegistrationDialog() {
    RegistrationDialog.show(
      context,
      confettiController: confettiController,
    );
  }
}
