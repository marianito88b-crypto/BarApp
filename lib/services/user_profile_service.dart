// lib/services/user_profile_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _usersRef = FirebaseFirestore.instance.collection('usuarios');

Future<bool> needsProfileCompletion(User user) async {
  final uid = user.uid;
  final isApple = user.providerData.any((p) => p.providerId == 'apple.com');
  
  // 🔍 1. Chequeo rápido: ¿Es Invitado (Anónimo)?
  if (user.isAnonymous) {
    final docSnapshot = await _usersRef.doc(uid).get();
    
    // Si no existe en base de datos, lo creamos y lo dejamos pasar
    if (!docSnapshot.exists) {
      await _usersRef.doc(uid).set({
        'displayName': 'Invitado', // Nombre por defecto
        'imageUrl': null,
        'hasCompletedProfile': true, // Importante para que no lo pida de nuevo
        'isGuest': true, // Flag útil para limitar funciones después (ej: no dejar comentar)
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    // Retornamos false para que AuthGate lo deje pasar directo al Home
    return false; 
  }

  // ---------------------------------------------------------
  // 🔍 2. Lógica para usuarios normales (Google, Apple, Email)
  // ---------------------------------------------------------

  final doc = await _usersRef.doc(uid).get();
  final authName = (user.displayName ?? '').trim();
  final authPhoto = user.photoURL;

  // 🔹 Si NO existe el doc de usuario en Firestore
  if (!doc.exists) {
    // Si ya trae nombre de Google/Apple, lo guardamos y pasa
    if (authName.isNotEmpty) {
      await _usersRef.doc(uid).set({
        'displayName': authName,
        'imageUrl': authPhoto,
        'hasCompletedProfile': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return false; // ✅ Pasa directo
    }
    // Si no trae nombre (ej: Email/Pass nuevo), pedimos completar
    return true; 
  }

  // 🔹 Si el doc SÍ existe, verificamos integridad
  final data = doc.data() ?? {};
  final name = (data['displayName'] ?? '').toString().trim();
  final hasCompleted = data['hasCompletedProfile'] == true;

  // Validación robusta: Si ya completó y tiene nombre real
  if (hasCompleted && name.isNotEmpty && name.toLowerCase() != 'sin nombre') {
    return false;
  }

  // Caso especial Apple: a veces el nombre llega tarde
  if ((name.isEmpty || name.toLowerCase() == 'sin nombre') && isApple && authName.isNotEmpty) {
      await _usersRef.doc(uid).set({
        'displayName': authName,
        'imageUrl': authPhoto,
        'hasCompletedProfile': true,
      }, SetOptions(merge: true));
      return false;
  }

  // Si llegamos acá, falta información -> AuthGate mostrará CompleteProfileScreen
  return true;
}