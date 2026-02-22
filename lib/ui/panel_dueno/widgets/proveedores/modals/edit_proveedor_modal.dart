import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../logic/proveedor_logic.dart';

/// Modal para editar los datos de un proveedor
class EditProveedorModal extends StatefulWidget {
  final String placeId;
  final String provId;
  final ProveedorLogicMixin mixin;

  const EditProveedorModal({
    super.key,
    required this.placeId,
    required this.provId,
    required this.mixin,
  });

  /// Método estático para mostrar el modal de forma conveniente
  static Future<void> show(
    BuildContext context, {
    required String placeId,
    required String provId,
    required ProveedorLogicMixin mixin,
  }) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('proveedores')
          .doc(provId)
          .get();

      if (!doc.exists) return;

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => EditProveedorModal(
          placeId: placeId,
          provId: provId,
          mixin: mixin,
        ),
      );
    } catch (e) {
      debugPrint("Error cargando datos del proveedor: $e");
    }
  }

  @override
  State<EditProveedorModal> createState() => _EditProveedorModalState();
}

class _EditProveedorModalState extends State<EditProveedorModal> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _rubroCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _cuitCtrl;
  bool _isLoading = false;
  Map<String, dynamic>? _initialData;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _nombreCtrl = TextEditingController();
    _rubroCtrl = TextEditingController();
    _telCtrl = TextEditingController();
    _cuitCtrl = TextEditingController();
  }

  Future<void> _cargarDatos() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('proveedores')
          .doc(widget.provId)
          .get();

      if (!doc.exists || !mounted) return;

      _initialData = doc.data() as Map<String, dynamic>;
      _nombreCtrl.text = _initialData!['nombre'] ?? '';
      _rubroCtrl.text = _initialData!['rubro'] ?? '';
      _telCtrl.text = _initialData!['telefono'] ?? '';
      _cuitCtrl.text = _initialData!['cuit'] ?? '';

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rubroCtrl.dispose();
    _telCtrl.dispose();
    _cuitCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualizarProveedor() async {
    if (_nombreCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    widget.mixin.setLoading(true);

    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('proveedores')
          .doc(widget.provId)
          .update({
        'nombre': _nombreCtrl.text,
        'rubro': _rubroCtrl.text,
        'telefono': _telCtrl.text,
        'cuit': _cuitCtrl.text,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Datos actualizados"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error actualizando proveedor: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.mixin.setLoading(false);
    }
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
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.orangeAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialData == null) {
      return const AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        content: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        "Editar Proveedor",
        style: TextStyle(color: Colors.orangeAccent),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_nombreCtrl, "Nombre / Razón Social"),
            const SizedBox(height: 10),
            _buildTextField(_rubroCtrl, "Rubro"),
            const SizedBox(height: 10),
            _buildTextField(_telCtrl, "Teléfono", isTel: true),
            const SizedBox(height: 10),
            _buildTextField(_cuitCtrl, "CUIT / CUIL"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("CANCELAR"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
          onPressed: _isLoading ? null : _actualizarProveedor,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  "ACTUALIZAR",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
