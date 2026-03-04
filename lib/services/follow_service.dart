import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 IMPORTAR ESTO
import 'package:flutter/foundation.dart'; // Para debugPrint

class FollowService {
  /// Realiza el Toggle (Follow/Unfollow) y devuelve el NUEVO contador.
  /// Además, gestiona la suscripción a notificaciones FCM.
  static Future<int?> toggleFollow({
    required String placeId,
    required bool isCurrentlyFollowing,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return null;

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);
    final followerRef = placeRef.collection('followers').doc(user.uid);

    final batch = FirebaseFirestore.instance.batch();
    int increment = 0;

    // 1. LÓGICA DE FIRESTORE (Base de datos)
    if (isCurrentlyFollowing) {
      // UNFOLLOW
      batch.update(userRef, {
        'followingBars': FieldValue.arrayRemove([placeId])
      });
      batch.update(placeRef, {
        'followersCount': FieldValue.increment(-1)
      });
      batch.delete(followerRef);
      increment = -1;
    } else {
      // FOLLOW
      batch.update(userRef, {
        'followingBars': FieldValue.arrayUnion([placeId])
      });
      batch.update(placeRef, {
        'followersCount': FieldValue.increment(1)
      });
      batch.set(followerRef, {
        'userId': user.uid,
        'displayName': user.displayName ?? 'Usuario',
        'imageUrl': user.photoURL ?? '',
        'followedAt': FieldValue.serverTimestamp(),
      });
      increment = 1;
    }

    // 2. 🔥 LÓGICA DE NOTIFICACIONES (FCM)
    // Esto conecta el botón con la nube para que lleguen los mensajes.
    if (!kIsWeb) {
    try {
      if (isCurrentlyFollowing) {
        // Dejar de seguir -> Ya no quiero notificaciones
        await FirebaseMessaging.instance.unsubscribeFromTopic('followers_$placeId');
        debugPrint("🔕 Desuscrito del topic: followers_$placeId");
      } else {
        // Seguir -> Quiero notificaciones
        await FirebaseMessaging.instance.subscribeToTopic('followers_$placeId');
        debugPrint("🔔 Suscrito al topic: followers_$placeId");
      }
    } catch (e) {
      // Si falla la suscripción (ej: en simulador a veces o sin internet),
      // no rompemos el flujo, solo lo logueamos.
      debugPrint("⚠️ Error gestionando suscripción FCM: $e");
    }
}
    // 3. CONFIRMAR CAMBIOS EN DB
    try {
      await batch.commit();
      return increment;
    } catch (e) {
      return null;
    }
  }
}