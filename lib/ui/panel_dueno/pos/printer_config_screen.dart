import 'package:flutter/material.dart';
import '../widgets/printer/printer_status_card.dart';
import '../widgets/printer/bluetooth_device_tile.dart';
import '../logic/printer_logic.dart';

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen>
    with PrinterLogicMixin {
  @override
  void initState() {
    super.initState();
    initPrinter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Configurar Impresora", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (connected)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.greenAccent),
              onPressed: testPrint,
              tooltip: "Imprimir Prueba",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESTADO
            PrinterStatusCard(
              isConnected: connected,
              deviceName: selectedDevice?.name,
            ),

            const SizedBox(height: 30),
            
            // TITULO LISTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dispositivos Emparejados", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Colors.orangeAccent),
                  onPressed: scanDevices,
                )
              ],
            ),
            const SizedBox(height: 10),
            const Text("Asegúrate de haber emparejado la impresora en la configuración Bluetooth de Android primero.", style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 10),

            // LISTA
            Expanded(
              child: devices.isEmpty
                  ? const Center(
                      child: Text(
                        "No se encontraron impresoras.",
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected =
                            selectedDevice?.address == device.address;

                        return BluetoothDeviceTile(
                          device: device,
                          isSelected: isSelected,
                          isConnected: isSelected && connected,
                          isConnecting: isSelected && isLoading,
                          onConnect: () => connect(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}