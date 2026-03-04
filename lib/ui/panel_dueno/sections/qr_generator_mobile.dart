import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/qr/qr_display_card.dart';

class QRGeneratorMobile extends StatefulWidget {
  final String placeId;
  const QRGeneratorMobile({super.key, required this.placeId});

  @override
  State<QRGeneratorMobile> createState() => _QRGeneratorMobileState();
}

class _QRGeneratorMobileState extends State<QRGeneratorMobile> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _compartirQR() async {
    setState(() => _isSaving = true);
    try {
      // 1. Renderizar el widget QR a imagen PNG
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // 2. Crear PDF de una página con el QR
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Escaneá para ver nuestro menú',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Image(pw.MemoryImage(pngBytes), width: 250, height: 250),
              ],
            ),
          ),
        ),
      );

      // 3. Abrir share sheet nativo (guardar, imprimir, enviar, etc.)
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'qr-mi-local.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: placeId vacío
    if (widget.placeId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text(
            'No se pudo cargar el QR.\nReintentá más tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      );
    }

    final String urlMenu = "https://barapp-social.web.app/?id=${widget.placeId}";

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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Text(
                  "Al escanear este código, tus clientes entrarán directo a tu menú digital.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),

              // RepaintBoundary para capturar el QR como imagen
              RepaintBoundary(
                key: _qrKey,
                child: QRDisplayCard(
                  data: urlMenu,
                  size: 240.0,
                ),
              ),

              const SizedBox(height: 30),

              // --- BOTÓN COPIAR ENLACE ---
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: urlMenu));
                  if (mounted) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.link),
                label: const Text("COPIAR ENLACE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 15),

              // --- BOTÓN GUARDAR / COMPARTIR QR ---
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _compartirQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(
                  _isSaving ? "Guardando..." : "GUARDAR / COMPARTIR QR",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
