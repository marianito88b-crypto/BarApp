import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  // Estado de los Switches
  bool _autoPrintComandas = false; // Para la Cocina
  bool _autoPrintCliente = false;  // Para el Cliente (Delivery/Retiro) - NUEVO
  bool _autoPrintReservas = false; // Para Reservas
  int _cantidadCopias = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Cargamos las configs existentes
      _autoPrintComandas = prefs.getBool('autoPrintComandas') ?? false;
      _autoPrintReservas = prefs.getBool('autoPrintReservas') ?? false;
      _cantidadCopias = prefs.getInt('cantidadCopias') ?? 1;
      
      // Cargamos la nueva config (por defecto false para no gastar papel si no quieren)
      _autoPrintCliente = prefs.getBool('autoPrintCliente') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    if (value is int) prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Configuración de Impresión", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN COCINA
          _buildSectionTitle("Área Cocina & Producción"),
          SwitchListTile(
            secondary: const Icon(Icons.soup_kitchen, color: Colors.orangeAccent),
            title: const Text("Impresión automática de Comandas", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Imprime ticket para el cocinero al 'Aceptar' o recibir pedidos.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _autoPrintComandas,
            activeThumbColor: Colors.orangeAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() => _autoPrintComandas = v);
              _saveSetting('autoPrintComandas', v);
            },
          ),

          const Divider(color: Colors.white10),

          // SECCIÓN CLIENTE (NUEVA)
          _buildSectionTitle("Área Cliente & Delivery"),
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long, color: Colors.greenAccent),
            title: const Text("Ticket de Entrega Automático", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Imprime ticket fiscal/envío al asignar chofer o marcar para retiro.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _autoPrintCliente,
            activeThumbColor: Colors.greenAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() => _autoPrintCliente = v);
              _saveSetting('autoPrintCliente', v); // 🔥 Nueva Key
            },
          ),

          const Divider(color: Colors.white10),

          // SECCIÓN RESERVAS
          _buildSectionTitle("Gestión de Reservas"),
          SwitchListTile(
            secondary: const Icon(Icons.event_seat, color: Colors.blueAccent),
            title: const Text("Imprimir tickets de reserva", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Imprime comprobante al confirmar una reserva.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _autoPrintReservas,
            activeThumbColor: Colors.blueAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() => _autoPrintReservas = v);
              _saveSetting('autoPrintReservas', v);
            },
          ),

          const Divider(color: Colors.white10),

          // SECCIÓN GENERAL
          _buildSectionTitle("Configuración General"),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.content_copy, color: Colors.white54),
            title: const Text("Copias por impresión", style: TextStyle(color: Colors.white)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                dropdownColor: const Color(0xFF1E1E1E),
                value: _cantidadCopias,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orangeAccent),
                items: [1, 2, 3].map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text("$e copias", style: const TextStyle(color: Colors.white))
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _cantidadCopias = v);
                    _saveSetting('cantidadCopias', v);
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Si desactivas estas opciones, siempre podrás imprimir manualmente usando los botones 🖨️ en cada tarjeta.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Text(
        title.toUpperCase(), 
        style: const TextStyle(
          color: Colors.orangeAccent, 
          fontWeight: FontWeight.bold, 
          fontSize: 11,
          letterSpacing: 1.0
        )
      ),
    );
  }
}