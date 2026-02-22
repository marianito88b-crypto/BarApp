import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

/// Widget que representa un dispositivo Bluetooth en la lista
/// 
/// Muestra el nombre, dirección y botón de conexión.
/// Usa color verde para dispositivos seleccionados y conectados.
class BluetoothDeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool isSelected;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;

  const BluetoothDeviceTile({
    super.key,
    required this.device,
    required this.isSelected,
    required this.isConnected,
    this.isConnecting = false,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: Colors.greenAccent) : null,
      ),
      child: ListTile(
        leading: const Icon(Icons.print, color: Colors.white70),
        title: Text(
          device.name ?? "Desconocido",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          device.address ?? "",
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        trailing: isSelected && isConnected
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnecting ? Colors.white24 : Colors.white10,
                  foregroundColor: isConnecting ? Colors.white54 : Colors.white,
                ),
                onPressed: isConnecting ? null : onConnect,
                child: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : const Text("Conectar"),
              ),
      ),
    );
  }
}
