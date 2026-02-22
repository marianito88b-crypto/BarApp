import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modal para agregar un nuevo proveedor
class AddProveedorModal extends StatefulWidget {
  final String placeId;

  const AddProveedorModal({
    super.key,
    required this.placeId,
  });

  @override
  State<AddProveedorModal> createState() => _AddProveedorModalState();
}

class _AddProveedorModalState extends State<AddProveedorModal> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController rubroController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController cuitController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nombreController.dispose();
    rubroController.dispose();
    telController.dispose();
    cuitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        "Nuevo Proveedor",
        style: TextStyle(color: Colors.orangeAccent),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(nombreController, "Nombre (Ej: Distribuidora X)"),
          const SizedBox(height: 10),
          _buildTextField(rubroController, "Rubro (Ej: Bebidas)"),
          const SizedBox(height: 10),
          _buildTextField(telController, "Teléfono", isTel: true),
          const SizedBox(height: 10),
          _buildTextField(cuitController, "CUIT / CUIL"),
          const SizedBox(height: 10),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
          ),
          onPressed: isLoading ? null : _guardarProveedor,
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Guardar",
                  style: TextStyle(color: Colors.black),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isTel = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isTel ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  Future<void> _guardarProveedor() async {
    if (nombreController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('proveedores')
          .add({
        'nombre': nombreController.text,
        'rubro': rubroController.text,
        'telefono': telController.text,
        'cuit': cuitController.text,
        'saldoPendiente': 0.0,
        'fechaCreado': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Proveedor agregado correctamente")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }
}
