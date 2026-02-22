import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestGuard {
  // 1. Verificamos si es invitado
  static bool isGuest() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  // 2. Función mágica para proteger acciones
  static void run(BuildContext context, {required VoidCallback action}) {
    if (isGuest()) {
      _showLoginModal(context);
    } else {
      action(); // Si no es invitado, ejecuta la función normalmente
    }
  }

  // 3. El Modal Estético (Premium Vibe)
  static void _showLoginModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.lock_person_rounded, color: Color(0xFFFF7F50), size: 50),
            const SizedBox(height: 16),
            const Text(
              "¡Unite a la fiesta!",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Para ver el muro social, eventos y conectar con otros, necesitas iniciar sesión con tu cuenta.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7F50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Cierra el modal
                  // 🔥 Cerramos sesión para que el AuthGate lo mande al Login
                  FirebaseAuth.instance.signOut();
                },
                child: const Text("Registrarme / Iniciar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Seguir explorando como invitado", style: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}