import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 📦 Widget oficial de Apple
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- AGREGAR ESTE
import 'package:firebase_auth/firebase_auth.dart'; // <--- AGREGÁ ESTA

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _errorMessage;
  bool _isLoading = false;

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setError(String? value) {
    if (mounted) setState(() => _errorMessage = value);
  }

  // ---------------------------
  // LÓGICA (Igual que antes)
  // ---------------------------
Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.signInWithGoogle();
      
      if (error == null) {
        await _syncUserData(); // 🔥 AGREGADO: Sincroniza datos si no hubo error
      } else {
        _setError(error);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loginWithApple() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.signInWithApple();
      
      if (error == null) {
        await _syncUserData(); // 🔥 AGREGADO
      } else {
        _setError(error);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loginAsGuest() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.signInAnonymously();
      
      if (error == null) {
        await _syncUserData(); // 🔥 AGREGADO (Incluso para invitados, así tienen antigüedad)
      } else {
        _setError(error);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
// --- FUNCIÓN PARA GUARDAR/ACTUALIZAR USUARIO EN FIRESTORE ---
  Future<void> _syncUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set({
        'displayName': user.displayName ?? 'Usuario',
        'imageUrl': user.photoURL ?? '',
        'email': user.email ?? '',
        'lastLogin': FieldValue.serverTimestamp(), // Para saber cuándo entró por última vez
        // Usamos 'set' con 'merge: true'. 
        // Si el campo 'createdAt' ya existe, no lo sobreescribe.
        // Si no existe (usuario nuevo), lo crea.
        'createdAt': FieldValue.serverTimestamp(), 
      }, SetOptions(merge: true));
      
      debugPrint("Datos de usuario sincronizados en Firestore");
    } catch (e) {
      debugPrint("Error sincronizando usuario: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un Stack para poner el fondo y el loading encima de todo
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo de seguridad
      body: Stack(
        children: [
          // 1. FONDO CON DEGRADADO
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E2C), // Azul oscuro noche
                  Color(0xFF000000), // Negro total
                ],
              ),
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO / BRANDING
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(
                        Icons.local_bar_rounded,
                        size: 60,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "BarApp",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tu guía nocturna empieza aquí",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // MENSAJE DE ERROR (Si existe)
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // BOTONES SOCIALES
                    
                    // 🍏 APPLE (Widget Oficial)
                    SignInWithAppleButton(
                      onPressed: _loginWithApple,
                      style: SignInWithAppleButtonStyle.white, // Estilo blanco destaca en fondo negro
                      height: 50,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      text: "Continuar con Apple",
                    ),
                    
                    const SizedBox(height: 16),

                    // 🔥 GOOGLE (Estilo Custom Moderno)
                    _GoogleButton(onPressed: _loginWithGoogle),

                    const SizedBox(height: 30),
                    
                    // DIVISOR
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("O", style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 👤 INVITADO (Minimalista)
                    TextButton(
                      onPressed: _loginAsGuest,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Entrar como Invitado"),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. LOADING OVERLAY (Capa de carga)
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }
}

// 🎨 WIDGET PERSONALIZADO PARA EL BOTÓN DE GOOGLE
class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lo ideal es usar un asset, pero si no tienes, este texto simula el logo
              // O puedes usar: Image.asset('assets/google_logo.png', height: 24),
              const Icon(Icons.g_mobiledata, color: Colors.black, size: 30), 
              const SizedBox(width: 12),
              const Text(
                "Continuar con Google",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 17, // Tamaño estándar de Apple/Google
                  fontWeight: FontWeight.w500,
                  fontFamily: '-apple-system', // Intenta usar la fuente del sistema
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}