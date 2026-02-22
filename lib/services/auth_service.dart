// lib/services/auth_service.dart
import 'dart:convert'; // 🔹 Para encoding
import 'dart:math';    // 🔹 Para generar randoms

import 'package:crypto/crypto.dart'; // 🔹 Para SHA256
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 🔹 El paquete de Apple
import 'package:flutter/foundation.dart'; // <--- IMPORTANTE: Para kIsWeb

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // ----------------------------------------------------
  // 🚀 1. AUTENTICACIÓN con Google (HÍBRIDA WEB/MÓVIL)
  // ----------------------------------------------------
  Future<String?> signInWithGoogle() async {
    try {
      // 🌐 A. LÓGICA PARA WEB (Usa Popup de Firebase directo)
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        
        // Esto abre una ventanita emergente segura de Google
        await _auth.signInWithPopup(authProvider);
        
        return null; // Éxito
      } 
      
      // 📱 B. LÓGICA PARA MÓVIL (Android/iOS - Tu código original)
      else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        
        // Cerramos sesión previa para permitir elegir cuenta de nuevo
        // (Opcional, pero recomendado si el usuario quiere cambiar de cuenta)
        // if (await googleSignIn.isSignedIn()) {
        //   await googleSignIn.signOut();
        // }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) return 'Inicio de sesión cancelado.';

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        return null; // Éxito
      }

    } on FirebaseAuthException catch (e) {
      debugPrint("Error Firebase Auth: ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("Error Google Sign In: $e");
      return 'Error con Google Sign-In.';
    }
  }
  // ----------------------------------------------------
  // 🍏 2. AUTENTICACIÓN con Apple (IMPLEMENTADA)
  // ----------------------------------------------------
  Future<String?> signInWithApple() async {
    try {
      // 1. Generar un "nonce" aleatorio (Requisito de seguridad de Firebase)
      final rawNonce = _generateNonce();
      final sha256Nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // 2. Pedir credenciales a Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce, // Enviamos el nonce encriptado a Apple
      );

      // 3. Crear credencial para Firebase
      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode, // A veces es null, Firebase lo maneja
        rawNonce: rawNonce, // Enviamos el nonce original a Firebase
      );

      // 4. Iniciar sesión
      await _auth.signInWithCredential(credential);
      return null; // Éxito

    } on FirebaseAuthException catch (e) {
      debugPrint("Error Firebase Apple: ${e.message}");
      return e.message;
    } on SignInWithAppleAuthorizationException catch (e) {
      // El usuario canceló el diálogo nativo
      debugPrint("Usuario canceló Apple Sign In: $e");
      return null; // No mostramos error, solo no loguea
    } catch (e) {
      debugPrint("Error genérico Apple: $e");
      return 'Error al iniciar sesión con Apple.';
    }
  }

  // ----------------------------------------------------
  // 👤 3. INVITADO
  // ----------------------------------------------------
  Future<String?> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al entrar como invitado.';
    }
  }

  // ----------------------------------------------------
  // 🛠️ UTILIDADES INTERNAS
  // ----------------------------------------------------
  
  // Función auxiliar para generar el string aleatorio
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // 4. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    if (await GoogleSignIn().isSignedIn()) {
      await GoogleSignIn().signOut();
    }
  }
}