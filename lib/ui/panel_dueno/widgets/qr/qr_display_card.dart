import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget que muestra un código QR con estilo neón naranja
/// 
/// Contenedor blanco con sombra neón naranja para destacar el QR
class QRDisplayCard extends StatelessWidget {
  final String data;
  final double size;

  const QRDisplayCard({
    super.key,
    required this.data,
    this.size = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        gapless: false,
      ),
    );
  }
}
