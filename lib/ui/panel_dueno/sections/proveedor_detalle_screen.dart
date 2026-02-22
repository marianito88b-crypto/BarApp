import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/proveedores/proveedor_header_info.dart';
import '../widgets/proveedores/proveedor_gasto_tile.dart';
import '../widgets/proveedores/proveedor_action_buttons.dart';
import '../logic/proveedor_logic.dart';

class ProveedorDetalleScreen extends StatefulWidget {
  final String placeId;
  final String provId;
  final String nombre;

  const ProveedorDetalleScreen({
    super.key, 
    required this.placeId, 
    required this.provId, 
    required this.nombre
  });

  @override
  State<ProveedorDetalleScreen> createState() => _ProveedorDetalleScreenState();
}

class _ProveedorDetalleScreenState extends State<ProveedorDetalleScreen>
    with ProveedorLogicMixin {
  @override
  String get placeId => widget.placeId;

  @override
  String get provId => widget.provId;

  @override
  String get nombreProveedor => widget.nombre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text(widget.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151515),
        elevation: 0,
        actions: [
          // MENÚ DE OPCIONES: EDITAR Y ELIMINAR
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') editProveedor();
              if (value == 'delete') deleteProveedor();
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text("Editar Datos", style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delete', child: Text("Eliminar Proveedor", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('places').doc(widget.placeId).collection('proveedores').doc(widget.provId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
          var provData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              ProveedorHeaderInfo(
                data: provData,
                onWhatsApp: () => abrirWhatsApp(provData['telefono'] ?? ''),
                onPhone: () => launchUrl(Uri.parse("tel:${provData['telefono'] ?? ''}")),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "HISTORIAL DE REMITOS / GASTOS",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildGastosAsociados()),
              ProveedorActionButtons(
                onPagoParcial: showPagoParcialDialog,
                onSaldarTodo: liquidarDeuda,
              ),
            ],
          );
        },
      ),
    );
  }


  // --- LISTADO CON ARREGLO DE ERROR "fotoUrl" ---
  Widget _buildGastosAsociados() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').doc(widget.placeId).collection('gastos')
          .where('proveedorId', isEqualTo: widget.provId)
          .orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var gasto = doc.data() as Map<String, dynamic>;
            String? fotoUrl = gasto.containsKey('fotoUrl') ? gasto['fotoUrl'] : null;

            return ProveedorGastoTile(
              gastoId: doc.id,
              gasto: gasto,
              onUploadPhoto: () => subirFotoRemito(doc.id),
              onViewPhoto: fotoUrl != null ? () => _verFoto(fotoUrl) : null,
            );
          },
        );
      },
    );
  }

  void _verFoto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}