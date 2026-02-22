import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barapp/ui/user/blocked_users_screen.dart';

/// Bottom sheet de ajustes y configuración
/// 
/// Muestra opciones de cuenta, legales y acciones peligrosas
class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BARRA SUPERIOR
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Ajustes y Legal",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // OPCIONES DE CUENTA
            SettingsTile(
              icon: Icons.block_rounded,
              label: "Usuarios Bloqueados",
              onTap: () {
                Navigator.pop(context); // Cerramos el menú
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlockedUsersScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, height: 1),

            // LEGALES (Funcionando con tus links de Firebase)
            SettingsTile(
              icon: Icons.description_outlined,
              label: "Términos de Uso (EULA)",
              onTap: () => _launchURL(context, "https://barapp-social.web.app/terms.html"),
            ),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: "Política de Privacidad",
              onTap: () => _launchURL(context, "https://barapp-social.web.app/privacy.html"),
            ),

            const SizedBox(height: 20),

            // ZONA DE PELIGRO
            SettingsTile(
              icon: Icons.logout_rounded,
              label: "Cerrar Sesión",
              color: Colors.orangeAccent,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              label: "Eliminar mi cuenta",
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog(context);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 FUNCIÓN CORREGIDA: Ahora sí abre los links
  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      // Usamos inAppBrowserView para que sea rápido y no saque al usuario de la app
      if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
        throw 'No se pudo abrir $urlString';
      }
    } catch (e) {
      debugPrint("Error abriendo link: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el enlace")),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Eliminar Cuenta?",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Esta acción es irreversible. Se borrará tu perfil, publicaciones y datos personales de nuestros servidores.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final String uid = user.uid;

                // 1. Borrar datos de Firestore
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .delete();

                // 2. Borrar el usuario de Firebase Auth
                await user.delete();

                if (context.mounted) {
                  // Cerramos el diálogo
                  Navigator.pop(ctx);

                  // Navegar a la pantalla de Login y limpiar el historial
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tu cuenta ha sido eliminada correctamente."),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) Navigator.pop(ctx);
                if (!context.mounted) return;

                if (e.code == 'requires-recent-login') {
                  _showErrorSnackBar(context,
                      "Por seguridad, cierra sesión e ingresa de nuevo antes de eliminar tu cuenta.");
                } else {
                  _showErrorSnackBar(context, "Error al eliminar: ${e.message}");
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(ctx);
                _showErrorSnackBar(context,
                    "Hubo un error inesperado al intentar borrar los datos.");
              }
            },
            child: const Text("Eliminar definitivamente"),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para mensajes
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

/// Tile individual dentro del bottom sheet de ajustes
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: color.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}
