// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barapp/providers/blocked_users_provider.dart';

/// Mixin que centraliza la lógica de negocio del perfil de usuario
/// 
/// Maneja carga de datos, bloqueo/reporte, selección/recorte de imágenes,
/// y subida a Storage/Firestore. Determina automáticamente si el perfil es propio o ajeno.
mixin ProfileLogicMixin<T extends StatefulWidget> on State<T> {
  // --- Estado interno ---
  late String _displayUserId;
  late bool _isViewingOwnProfile;
  User? _loggedInUser;
  late Future<Map<String, dynamic>> _combinedFuture;
  final _usersCollection = FirebaseFirestore.instance.collection('usuarios');

  // --- Getters públicos ---
  String get displayUserId => _displayUserId;
  bool get isViewingOwnProfile => _isViewingOwnProfile;
  User? get loggedInUser => _loggedInUser;
  Future<Map<String, dynamic>> get combinedFuture => _combinedFuture;

  /// Inicializa la lógica del perfil
  /// 
  /// Determina automáticamente si el perfil es propio o ajeno basándose en
  /// el externalUserId proporcionado y el usuario actual autenticado.
  /// 
  /// Debe llamarse en initState del State que usa este Mixin.
  void initProfileLogic(String? externalUserId) {
    _loggedInUser = FirebaseAuth.instance.currentUser;

    // 🔥 MEJORA: Determinación automática de perfil propio/ajeno
    if (externalUserId == null ||
        (_loggedInUser != null && externalUserId == _loggedInUser!.uid)) {
      _isViewingOwnProfile = true;
      _displayUserId = _loggedInUser?.uid ?? 'error';
    } else {
      _isViewingOwnProfile = false;
      _displayUserId = externalUserId;
    }

    final targetId =
        _isViewingOwnProfile ? _loggedInUser?.uid : externalUserId;

    final profileFuture = _getProfileData(targetId);
    final reviewsFuture = _fetchUserDataAndReviews(_displayUserId);

    _combinedFuture = Future.wait([profileFuture, reviewsFuture]).then((list) {
      final profile = list[0];
      final reviewsStats = list[1];
      // Combinar de forma segura
      return <String, dynamic>{
        ...profile,
        ...reviewsStats,
      };
    }).catchError((error) {
      debugPrint('Error combinando datos del perfil: $error');
      // Retornar estructura por defecto en caso de error
      return <String, dynamic>{
        'firestore': null,
        'reviews': const [],
        'stats': const {'count': 0, 'avg': 0.0},
      };
    });
  }

  /// Refresca los datos combinados del perfil
  void refreshCombinedFuture() {
    final profileUserId = _isViewingOwnProfile
        ? _loggedInUser?.uid
        : _displayUserId;
    final profileFuture = _getProfileData(profileUserId);
    final reviewsFuture = _fetchUserDataAndReviews(_displayUserId);

    setState(() {
      _combinedFuture = Future.wait([profileFuture, reviewsFuture]).then((list) {
        final profile = list[0];
        final reviewsStats = list[1];
        return <String, dynamic>{
          ...profile,
          ...reviewsStats,
        };
      }).catchError((error) {
        debugPrint('Error refrescando datos del perfil: $error');
        return <String, dynamic>{
          'firestore': null,
          'reviews': const [],
          'stats': const {'count': 0, 'avg': 0.0},
        };
      });
    });
  }

  // ---------- LOGICA DE BLOQUEO Y REPORTE (OPTIMIZADA CON PROVIDER) ----------

  /// Maneja la acción de bloquear/desbloquear un usuario
  /// 
  /// Usa el BlockedUsersProvider para optimizar el estado y evitar rebuilds innecesarios.
  /// Recibe nombre y foto del usuario para guardarlos en el Provider.
  Future<void> handleBlockAction(
    BuildContext context, {
    required String userName,
    required String? userPhoto,
  }) async {
    // Usamos 'listen: false' porque esto es una acción puntual, no necesitamos redibujar aquí
    final provider = Provider.of<BlockedUsersProvider>(context, listen: false);
    final isAlreadyBlocked = provider.shouldHide(_displayUserId);

    if (isAlreadyBlocked) {
      // --- CASO: DESBLOQUEAR ---
      await provider.unblock(_displayUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario desbloqueado'),
            backgroundColor: Colors.green,
          ),
      );
    } else {
      // --- CASO: BLOQUEAR (Con datos visuales) ---
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            '¿Bloquear a $userName?',
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No verás sus reseñas, fotos ni recibirás mensajes de esta persona. ¿Estás seguro?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, bloquear'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (confirm == true) {
        // 🔥 AQUÍ PASAMOS LA DATA AL PROVIDER
        await provider.block(
          _displayUserId,
          name: userName,
          photoUrl: userPhoto,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario bloqueado correctamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Opcional: Salir del perfil para no verlo más
        Navigator.pop(context);
      }
    }
  }

  /// Maneja la acción de reportar un usuario
  /// 
  /// Guarda el reporte en Firestore y abre el cliente de email.
  void handleReportAction(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Reportar Usuario',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Si este usuario está incumpliendo las normas, enviaremos un reporte a moderación.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // 1. Guardar en Firestore (Opción PRO para tu panel de admin)
              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reportedUserId': _displayUserId,
                  'reportedBy': _loggedInUser?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'reason': 'Reporte desde perfil de usuario',
                });
              } catch (_) {}

              // 2. Abrir Email (Opción Legacy/Requisito Apple)
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'soporte.barapp@gmail.com',
                query:
                    'subject=Reporte de usuario $_displayUserId&body=ID Reportado: $_displayUserId\nMotivo: ',
              );
              launchUrl(emailLaunchUri);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gracias. Hemos recibido tu reporte.'),
                  backgroundColor: Colors.amber,
                ),
              );
            },
            child: const Text(
              'Reportar',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- DATA ----------

  /// Obtiene los datos del perfil desde Firestore
  Future<Map<String, dynamic>> _getProfileData(String? userId) async {
    if (userId == null || userId.isEmpty || userId == 'error') {
      return {
        'firestore': null,
        'reviews': const [],
        'stats': const {'count': 0, 'avg': 0.0},
      };
    }

    DocumentSnapshot<Map<String, dynamic>>? firestoreDoc;
    try {
      firestoreDoc = await _usersCollection.doc(userId).get();
    } catch (e) {
      debugPrint('Error Firestore obteniendo perfil: $e');
      return {
        'firestore': null,
        'reviews': const [],
        'stats': const {'count': 0, 'avg': 0.0},
      };
    }

    return {'firestore': firestoreDoc.data()};
  }

  /// Obtiene las reseñas y estadísticas del usuario
  Future<Map<String, dynamic>> _fetchUserDataAndReviews(String userId) async {
    if (userId == 'error') {
      return {
        'reviews': const [],
        'stats': const {'count': 0, 'avg': 0.0},
      };
    }
    try {
      final reviewsQuery = await FirebaseFirestore.instance
          .collectionGroup('ratings')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final reviews = reviewsQuery.docs.map((doc) => doc.data()).toList();

      double totalRating = 0;
      for (final review in reviews) {
        totalRating += (review['rating'] as num? ?? 0).toDouble();
      }
      final double avgRating =
          reviews.isEmpty ? 0 : totalRating / reviews.length;

      return {
        'reviews': reviews,
        'stats': {'count': reviews.length, 'avg': avgRating},
      };
    } catch (e) {
      debugPrint("⚠️ Error obteniendo reseñas: $e");
      return {
        'reviews': const [],
        'stats': const {'count': 0, 'avg': 0.0},
      };
    }
  }

  // ---------- PICK + CROP ----------

  /// Selecciona una imagen desde la galería
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }

  /// Recorta una imagen con las proporciones adecuadas
  /// 
  /// [isAvatar]: true para recorte cuadrado (1:1), false para recorte 16:9 (fondo)
  Future<File?> cropImage({required File file, required bool isAvatar}) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        aspectRatio: isAvatar
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isAvatar ? 'Recortar foto' : 'Recortar fondo',
            lockAspectRatio: true,
            initAspectRatio: isAvatar
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
          ),
          IOSUiSettings(
            title: isAvatar ? 'Recortar foto' : 'Recortar fondo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      debugPrint('Error recortando imagen: $e');
      return null;
    }
  }

  // ---------- UPLOADS ----------

  /// Sube una foto de perfil (avatar) a Storage y actualiza Firestore
  /// 
  /// Selecciona, recorta y sube la imagen. Actualiza tanto Firebase Auth
  /// como Firestore con la nueva URL.
  Future<void> uploadProfilePicture() async {
    if (!_isViewingOwnProfile || _loggedInUser == null) return;

    final picked = await pickImage();
    if (picked == null) return;
    final cropped = await cropImage(file: picked, isAvatar: true);
    if (cropped == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${_loggedInUser!.uid}.jpg');
      await ref.putFile(cropped);
      final url = await ref.getDownloadURL();

      await _loggedInUser!.updatePhotoURL(url);
      await _loggedInUser!.reload();
      _loggedInUser = FirebaseAuth.instance.currentUser;
      await _usersCollection.doc(_loggedInUser!.uid).set({
        'imageUrl': url,
      }, SetOptions(merge: true));

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Foto actualizada!')),
        );
      }
    } catch (e) {
      debugPrint('Error subiendo foto de perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sube una imagen de fondo a Storage y actualiza Firestore
  /// 
  /// Selecciona, recorta y sube la imagen de fondo del perfil.
  Future<void> uploadBackgroundImage() async {
    if (!_isViewingOwnProfile || _loggedInUser == null) return;

    final picked = await pickImage();
    if (picked == null) return;
    final cropped = await cropImage(file: picked, isAvatar: false);
    if (cropped == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_backgrounds')
          .child('${_loggedInUser!.uid}.jpg');
      await ref.putFile(cropped);
      final url = await ref.getDownloadURL();
      await _usersCollection.doc(_loggedInUser!.uid).set({
        'backgroundUrl': url,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Fondo actualizado!')),
        );
      }
      refreshCombinedFuture();
    } catch (e) {
      debugPrint('Error subiendo fondo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir el fondo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
