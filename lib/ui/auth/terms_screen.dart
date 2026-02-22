// lib/ui/auth/terms_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _isAccepted = false;
  bool _isLoading = false;

  // ⚡ OPTIMIZACIÓN 1: Usamos la extensión .html directa.
  // Esto evita que Firebase tenga que procesar el rewrite, ahorrando unos milisegundos.
  final Uri _termsUrl = Uri.parse('https://barapp-social.web.app/terms.html'); 
  final Uri _privacyUrl = Uri.parse('https://barapp-social.web.app/privacy.html');

  // 🎨 ESTILOS CONSTANTES (Mejor rendimiento que crearlos en cada build)
  static const Color brandOrange = Color(0xFFFF6B00); 
  static const Color backgroundColor = Color(0xFF121212);
  static const Color containerColor = Color(0xFF212121); // Grey[900] aprox
  static const Color containerBorderColor = Color(0xFF424242); // Grey[800] aprox

  Future<void> _launchUrl(Uri url) async {
    try {
      // ⚡ OPTIMIZACIÓN 2: Usamos inAppBrowserView.
      // Carga mucho más rápido porque no cierra tu app, solo superpone el navegador.
      if (!await launchUrl(
        url, 
        mode: LaunchMode.inAppBrowserView,
        // Opcional: Personalizar el navegador para que combine con tu app
        browserConfiguration: const BrowserConfiguration(
          showTitle: true,
        ),
      )) {
        throw Exception('No se pudo lanzar la URL');
      }
    } catch (e) {
      debugPrint('Error abriendo link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace. Verifica tu conexión.')),
        );
      }
    }
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'termsAccepted': true,
          'termsVersion': '1.0',
          'acceptedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // El AuthGate se encarga del resto
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de conexión: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              
              // --- ICONO ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: brandOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, size: 60, color: brandOrange),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // --- TÍTULOS ---
              const Text(
                'Te damos la bienvenida',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para comenzar a descubrir los mejores bares y eventos, necesitamos que aceptes nuestras reglas de convivencia.',
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
              
              const Spacer(flex: 2),

              // --- CAJA DE ACEPTACIÓN ---
              Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: containerBorderColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // ⚡ UX PRO: Permitir tocar toda la caja para activar el check, no solo el cuadradito
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _isAccepted = !_isAccepted),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _isAccepted,
                              activeColor: brandOrange,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white54, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _isAccepted = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                children: [
                                  const TextSpan(text: 'He leído y acepto los '),
                                  _buildLinkSpan('Términos y Condiciones', () => _launchUrl(_termsUrl)),
                                  const TextSpan(text: ' y la '),
                                  _buildLinkSpan('Política de Privacidad', () => _launchUrl(_privacyUrl)),
                                  const TextSpan(text: ' de BarApp, y confirmo que soy mayor de 18 años.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- BOTÓN CONTINUAR ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isAccepted && !_isLoading) ? _acceptTerms : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: _isAccepted ? 8 : 0,
                    shadowColor: brandOrange.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('INGRESAR AHORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para links limpios
  TextSpan _buildLinkSpan(String text, VoidCallback onTap) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: brandOrange,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationColor: brandOrange,
      ),
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }
}