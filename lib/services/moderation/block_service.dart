// lib/services/moderation/block_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BlockService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Nombres de las subcolecciones
  static const String _collectionUsers = 'usuarios';
  static const String _subBlockedUsers = 'blockedUsers'; // A quién bloqueé yo
  static const String _subBlockedBy = 'blockedBy';       // Quién me bloqueó a mí

  // 🔥 ESTA ES LA FUNCIÓN QUE EL COMPILADOR NO ENCUENTRA ACTUALIZADA
  static Future<void> blockUser(String userToBlockId, {String? name, String? photoUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("No hay usuario logueado");
    
    final myUid = currentUser.uid;

    // Referencia 1: MI lista (blockedUsers)
    final myBlockRef = _db
        .collection(_collectionUsers)
        .doc(myUid)
        .collection(_subBlockedUsers)
        .doc(userToBlockId);

    // Referencia 2: Su lista (blockedBy)
    final otherBlockedByRef = _db
        .collection(_collectionUsers)
        .doc(userToBlockId)
        .collection(_subBlockedBy)
        .doc(myUid);

    try {
      await _db.runTransaction((transaction) async {
        // En MI lista guardamos los datos visuales
        transaction.set(myBlockRef, {
          'blockedAt': FieldValue.serverTimestamp(),
          'uid': userToBlockId,
          'displayName': name ?? 'Usuario', 
          'photoUrl': photoUrl,             
        });

        // En SU lista solo el ID
        transaction.set(otherBlockedByRef, {
          'blockedAt': FieldValue.serverTimestamp(),
          'uid': myUid,
        });
      });
      debugPrint("🔒 Bloqueo exitoso con datos visuales");
    } catch (e) {
      debugPrint("❌ Error bloqueando: $e");
      rethrow;
    }
  }

  /// 🔓 DESBLOQUEAR USUARIO
  static Future<void> unblockUser(String userToUnblockId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final myUid = currentUser.uid;

    final myBlockRef = _db
        .collection(_collectionUsers)
        .doc(myUid)
        .collection(_subBlockedUsers)
        .doc(userToUnblockId);

    final otherBlockedByRef = _db
        .collection(_collectionUsers)
        .doc(userToUnblockId)
        .collection(_subBlockedBy)
        .doc(myUid);

    try {
      await _db.runTransaction((transaction) async {
        transaction.delete(myBlockRef);
        transaction.delete(otherBlockedByRef);
      });
      debugPrint("🔓 Desbloqueo exitoso");
    } catch (e) {
      debugPrint("❌ Error al desbloquear: $e");
      rethrow;
    }
  }

  /// ⚡ LISTA NEGRA COMBINADA
  static Future<Set<String>> getAllExcludedUserIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final myBlocksSnapshot = await _db
          .collection(_collectionUsers)
          .doc(currentUser.uid)
          .collection(_subBlockedUsers)
          .get();

      final blockedBySnapshot = await _db
          .collection(_collectionUsers)
          .doc(currentUser.uid)
          .collection(_subBlockedBy)
          .get();

      final Set<String> excludedIds = {};

      for (var doc in myBlocksSnapshot.docs) {
        excludedIds.add(doc.id);
      }
      for (var doc in blockedBySnapshot.docs) {
        excludedIds.add(doc.id);
      }

      return excludedIds;
    } catch (e) {
      debugPrint("⚠️ Error obteniendo lista de exclusión: $e");
      return {};
    }
  }
}