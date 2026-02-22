import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Diálogo de registro para invitados
/// 
/// Muestra opciones para descargar la app desde Google Play o App Store
class RegistrationDialog {
  /// Muestra el diálogo de registro con botones de tienda
  static void show(
    BuildContext context, {
    required ConfettiController confettiController,
  }) {
    const String androidUrl =
        "https://play.google.com/store/apps/details?id=com.mariano.barapp";
    const String iosUrl = "https://apps.apple.com/ar/app/barapp/id6757483657";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 15, 24, 40),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.orangeAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 35),

            // Icono con pulso sutil
            const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 55),
            const SizedBox(height: 25),

            const Text(
              "¡BarApp es mejor en tu celu!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              "Descargá la app y desbloqueá el poder de calificar tus lugares favoritos, reservar mesas al toque y pedir sin moverte del lugar. ¡Es gratis y para siempre!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),

            // TIENDAS CON ESTILO APPLE/GOOGLE
            Row(
              children: [
                Expanded(
                  child: _StoreButton(
                    icon: FontAwesomeIcons.googlePlay,
                    storeName: "Google Play",
                    subText: "DISPONIBLE EN",
                    color: const Color(0xFF202124),
                    url: androidUrl,
                    confettiController: confettiController,
                    context: ctx,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StoreButton(
                    icon: FontAwesomeIcons.apple,
                    storeName: "App Store",
                    subText: "CONSIGUELO EN EL",
                    color: const Color(0xFF202124),
                    url: iosUrl,
                    confettiController: confettiController,
                    context: ctx,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "QUIERO SEGUIR EXPLORANDO",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de tienda (Google Play / App Store)
class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String storeName;
  final String subText;
  final Color color;
  final String url;
  final ConfettiController confettiController;
  final BuildContext context;

  const _StoreButton({
    required this.icon,
    required this.storeName,
    required this.subText,
    required this.color,
    required this.url,
    required this.confettiController,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // 1. Efecto visual
        confettiController.play();

        // 2. Feedback al usuario
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text("¡Yendo a la tienda! 🚀"),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 2),
          ),
        );

        // 3. Abrir URL Real
        final Uri uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("No se pudo abrir la tienda: $e");
        }

        // 4. Cerrar modal
        if (this.context.mounted) Navigator.pop(this.context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  storeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
