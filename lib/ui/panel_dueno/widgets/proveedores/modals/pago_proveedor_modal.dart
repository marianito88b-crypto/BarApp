import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../logic/proveedor_logic.dart';

/// Modal para registrar un pago parcial a un proveedor
class PagoProveedorModal extends StatefulWidget {
  final String placeId;
  final String provId;
  final String nombreProveedor;
  final ProveedorLogicMixin mixin;

  const PagoProveedorModal({
    super.key,
    required this.placeId,
    required this.provId,
    required this.nombreProveedor,
    required this.mixin,
  });

  /// Método estático para mostrar el modal de forma conveniente
  static Future<void> show(
    BuildContext context, {
    required String placeId,
    required String provId,
    required String nombreProveedor,
    required ProveedorLogicMixin mixin,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PagoProveedorModal(
        placeId: placeId,
        provId: provId,
        nombreProveedor: nombreProveedor,
        mixin: mixin,
      ),
    );
  }

  @override
  State<PagoProveedorModal> createState() => _PagoProveedorModalState();
}

class _PagoProveedorModalState extends State<PagoProveedorModal> {
  final TextEditingController _pagoController = TextEditingController();
  String _metodo = "Efectivo";
  bool _isProcessing = false;

  @override
  void dispose() {
    _pagoController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    if (_pagoController.text.isEmpty) return;

    final double monto =
        double.tryParse(_pagoController.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) return;

    setState(() => _isProcessing = true);
    widget.mixin.setLoading(true);

    try {
      final proveedorRef = FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('proveedores')
          .doc(widget.provId);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(proveedorRef);
        final saldoActual = (snap['saldoPendiente'] ?? 0).toDouble();

        // 1️⃣ Actualizamos saldo del proveedor
        tx.update(proveedorRef, {'saldoPendiente': saldoActual - monto});

        // 2️⃣ Registramos el movimiento en gastos (vinculado a la caja)
        final nuevoGastoRef = FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .collection('gastos')
            .doc();

        tx.set(nuevoGastoRef, {
          'monto': monto,
          'categoria': 'Pago a Proveedor',
          'descripcion': 'Entrega a cuenta: ${widget.nombreProveedor} ($_metodo)',
          'proveedorId': widget.provId,
          'estado': 'pagado',
          'metodoPago': _metodo.toLowerCase() == 'efectivo'
              ? 'efectivo'
              : 'digital',
          'fecha': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pago registrado y restado de caja"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error registrando pago parcial: $e");
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
        setState(() => _isProcessing = false);
      }
      widget.mixin.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setST) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Registrar Entrega de Dinero",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pagoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: "Monto entregado",
                labelStyle: TextStyle(color: Colors.white54),
                prefixText: "\$ ",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _metodo,
              dropdownColor: const Color(0xFF1A1A1A),
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: ["Efectivo", "Transferencia", "Caja Chica"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setST(() => _metodo = val!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: _isProcessing ? null : _registrarPago,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    "REGISTRAR",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
