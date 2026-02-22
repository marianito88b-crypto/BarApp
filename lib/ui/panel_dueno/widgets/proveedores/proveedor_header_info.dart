import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que muestra la información del header del proveedor
/// 
/// Incluye CUIT, rubro, botones de contacto (WhatsApp y teléfono)
/// y el contador de deuda/saldo pendiente.
class ProveedorHeaderInfo extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onWhatsApp;
  final VoidCallback onPhone;

  const ProveedorHeaderInfo({
    super.key,
    required this.data,
    required this.onWhatsApp,
    required this.onPhone,
  });

  @override
  Widget build(BuildContext context) {
    final double deudaTotal = (data['saldoPendiente'] ?? 0).toDouble();

    late final String label;
    late final Color colorTotal;

    if (deudaTotal > 0) {
      label = "SALDO PENDIENTE";
      colorTotal = Colors.redAccent;
    } else if (deudaTotal < 0) {
      label = "SALDO A FAVOR";
      colorTotal = Colors.blueAccent;
    } else {
      label = "AL DÍA";
      colorTotal = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      if (data['cuit'] != null &&
                          data['cuit'].toString().isNotEmpty) {
                        Clipboard.setData(
                          ClipboardData(text: data['cuit'].toString()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("📋 CUIT copiado al portapapeles"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Text(
                      "CUIT: ${data['cuit'] ?? 'No cargado'}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    "RUBRO: ${data['rubro'] ?? '-'}",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onWhatsApp,
                    icon: const Icon(
                      Icons.message,
                      color: Color(0xFF25D366),
                    ),
                  ),
                  IconButton(
                    onPressed: onPhone,
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Contador de deuda
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorTotal.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorTotal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "\$${deudaTotal.abs().toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
