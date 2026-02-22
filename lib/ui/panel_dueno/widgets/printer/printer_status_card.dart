import 'package:flutter/material.dart';

/// Widget que muestra el estado de conexión de la impresora
/// 
/// Usa colores temáticos: Verde para conectado, Rojo para desconectado
class PrinterStatusCard extends StatelessWidget {
  final bool isConnected;
  final String? deviceName;

  const PrinterStatusCard({
    super.key,
    required this.isConnected,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? Colors.green
              : Colors.redAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? Colors.green : Colors.redAccent,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? "CONECTADO" : "DESCONECTADO",
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (deviceName != null)
                  Text(
                    deviceName!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
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
