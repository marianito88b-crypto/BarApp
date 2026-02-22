import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingsService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitRating({
    required String placeId,
    required int rating, // 1..5
    String? comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final doc = _db.collection('places').doc(placeId).collection('ratings').doc(user.uid);

    await doc.set({
      'rating': rating,
      'comment': comment ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario',
      'userAvatarUrl': user.photoURL ?? '',
    }, SetOptions(merge: true));
    // 🔥 Agregados se actualizan por Cloud Function (no acá)
  }

  /// Lectura rápida para tarjetas/lista
  Stream<DocumentSnapshot<Map<String, dynamic>>> placeAggregateStream(String placeId) {
    return _db.collection('places').doc(placeId).snapshots();
  }

  /// Comentarios del detalle (paginable)
  Query<Map<String, dynamic>> ratingsQuery(String placeId, {int pageSize = 20}) {
    return _db.collection('places')
      .doc(placeId)
      .collection('ratings')
      .orderBy('timestamp', descending: true)
      .limit(pageSize);
  }
}