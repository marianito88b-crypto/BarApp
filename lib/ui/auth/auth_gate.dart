// lib/screens/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para chequear términos en tiempo real

import 'complete_profile_screen.dart';
import 'package:barapp/services/user_profile_service.dart';

// TUS PANTALLAS
import 'package:barapp/ui/auth/login_screen.dart';
import 'package:barapp/ui/home_shell.dart'; 
import 'package:barapp/ui/auth/terms_screen.dart'; // <--- IMPORTA LA NUEVA PANTALLA AQUÍ

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;
  Stream<DocumentSnapshot>? _userDocStream;
  String? _cachedUid;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  Stream<DocumentSnapshot> _getUserDocStream(String uid) {
    if (_cachedUid != uid) {
      _cachedUid = uid;
      _userDocStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .snapshots();
    }
    return _userDocStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snap) {
        // 1. Cargando estado de autenticación
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        
        // 2. Si NO hay usuario → Login
        if (user == null) {
          return const LoginScreen();
        }

        // 3. Si HAY usuario → Verificamos TÉRMINOS Y CONDICIONES
        // Usamos un StreamBuilder de Firestore para detectar al instante si acepta
        return StreamBuilder<DocumentSnapshot>(
          stream: _getUserDocStream(user.uid),
          builder: (context, userSnap) {
            
            // Esperando a leer la base de datos...
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Datos del usuario
            final userData = userSnap.data?.data() as Map<String, dynamic>?;
            final bool termsAccepted = userData?['termsAccepted'] ?? false;

            // 🛑 BLOQUEO: Si no aceptó términos, mostramos la pantalla de aceptación
            if (!termsAccepted) {
              return const TermsAcceptanceScreen();
            }

            // ✅ Si aceptó términos → Verificamos si debe COMPLETAR PERFIL (Tu lógica original)
            return FutureBuilder<bool>(
              future: needsProfileCompletion(user),
              builder: (context, snap2) {
                if (!snap2.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final mustComplete = snap2.data ?? false;

                if (mustComplete) {
                  return CompleteProfileScreen(user: user);
                } else {
                  // 🏁 Todo listo: Bienvenido a la App
                  return const HomeShell();
                }
              },
            );
          },
        );
      },
    );
  }
}