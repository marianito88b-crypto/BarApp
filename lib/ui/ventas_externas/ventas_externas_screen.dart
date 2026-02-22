
import 'package:flutter/material.dart';
import 'venta_rapida_tab.dart';
import 'package:barapp/ui/panel_dueno/sections/ventas_externas_productos_screen.dart';

class VentasExternasScreen extends StatefulWidget {
  final String placeId;
  const VentasExternasScreen({super.key, required this.placeId});

  @override
  State<VentasExternasScreen> createState() => _VentasExternasScreenState();
}

class _VentasExternasScreenState extends State<VentasExternasScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Ventas Externas"),
        backgroundColor: const Color(0xFF151515),
      ),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [_tab == 0, _tab == 1],
            onPressed: (i) => setState(() => _tab = i),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.black,
            fillColor: Colors.orangeAccent,
            color: Colors.white54,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("RÁPIDA"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("CON PRODUCTOS"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? VentaRapidaTab(placeId: widget.placeId)
                : VentasExternasProductosScreen(placeId: widget.placeId),
          ),
        ],
      ),
    );
  }
}