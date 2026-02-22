import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/qr/qr_display_card.dart';

class QRGeneratorMobile extends StatelessWidget {
  final String placeId;
  const QRGeneratorMobile({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    // ESTA ES LA URL QUE EL CLIENTE VA A ESCANEAR
    final String urlMenu = "https://barapp-social.web.app/?id=$placeId";

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.orangeAccent, size: 50),
              const SizedBox(height: 10),
              const Text("QR DE TU LOCAL", 
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Text("Al escanear este código, tus clientes entrarán directo a tu menú digital.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
              const SizedBox(height: 20),
              
              // --- EL QR ---
              QRDisplayCard(
                data: urlMenu,
                size: 240.0,
              ),
              
              const SizedBox(height: 30),
              
              // --- BOTÓN DE COPIAR ENLACE ---
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: urlMenu));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Enlace copiado al portapapeles"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.link),
                label: const Text("COPIAR ENLACE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 15),
              
              // --- BOTÓN DE AYUDA ---
              ElevatedButton.icon(
                onPressed: () {
                  // Tip: Decile que le saque captura por ahora
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Sacale una captura de pantalla para imprimirlo!"))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text("GUARDAR QR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}