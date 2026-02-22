import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const List<String> categoriasGastos = [
  'Mercadería (Alimentos)',
  'Bebidas/Bar',
  'Servicios (Luz, Gas, Agua, Net)',
  'Sueldos / Adelantos',
  'Alquiler',
  'Mantenimiento / Reparaciones',
  'Impuestos (AFIP, Tasa)',
  'Otros / Varios',
];

/// Modal para agregar un nuevo gasto o remito
class AddGastoModal extends StatefulWidget {
  final String placeId;

  const AddGastoModal({
    super.key,
    required this.placeId,
  });

  @override
  State<AddGastoModal> createState() => _AddGastoModalState();
}

class _AddGastoModalState extends State<AddGastoModal> {
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController remitoController = TextEditingController();

  String categoriaSeleccionada = categoriasGastos[0];
  String? proveedorId;
  bool esDeuda = false;
  String metodoPago = 'efectivo';
  bool isLoading = false;

  @override
  void dispose() {
    montoController.dispose();
    descController.dispose();
    remitoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "NUEVO GASTO / REMITO",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .doc(widget.placeId)
                  .collection('proveedores')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                return DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Proveedor (Opcional)",
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: snapshot.data!.docs
                      .map((doc) => DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nombre']),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => proveedorId = val),
                );
              },
            ),

            SwitchListTile(
              title: const Text(
                "¿Es pago pendiente? (A pagar)",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              value: esDeuda,
              activeThumbColor: Colors.orangeAccent,
              onChanged: (val) => setState(() => esDeuda = val),
            ),

            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Monto total",
                prefixText: "\$ ",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: categoriaSeleccionada,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Categoría",
                labelStyle: TextStyle(color: Colors.white54),
              ),
              items: categoriasGastos
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => categoriaSeleccionada = val!),
            ),

            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Descripción",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),

            TextField(
              controller: remitoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nro de Remito (Opcional)",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 20),

            if (!esDeuda) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "¿Cómo se pagó?",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Row(
                children: [
                RadioGroup<String>(
                  groupValue: metodoPago,
                  onChanged: (val) => setState(() => metodoPago = val ?? metodoPago),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            "Efectivo",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          value: 'efectivo',
                          activeColor: Colors.orangeAccent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            "Digital",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          value: 'digital',
                          activeColor: Colors.orangeAccent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
              if (metodoPago == 'efectivo') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Este monto se descontará del saldo actual de la caja",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                ),
                onPressed: isLoading ? null : _guardarGasto,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "GUARDAR",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarGasto() async {
    if (montoController.text.isEmpty) return;

    setState(() => isLoading = true);

    final double monto =
        double.tryParse(montoController.text.replaceAll(',', '.')) ?? 0.0;
    final placeRef =
        FirebaseFirestore.instance.collection('places').doc(widget.placeId);

    try {
      if (esDeuda && proveedorId != null) {
        final proveedorRef =
            placeRef.collection('proveedores').doc(proveedorId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final provSnap = await tx.get(proveedorRef);
          final saldoActual =
              (provSnap.data()?['saldoPendiente'] ?? 0.0).toDouble();
          tx.update(proveedorRef, {'saldoPendiente': saldoActual + monto});
          tx.set(placeRef.collection('gastos').doc(), {
            'monto': monto,
            'categoria': categoriaSeleccionada,
            'descripcion': descController.text,
            'nroRemito': remitoController.text,
            'proveedorId': proveedorId,
            'estado': 'pendiente',
            'fecha': FieldValue.serverTimestamp(),
          });
        });
      } else {
        await placeRef.collection('gastos').add({
          'monto': monto,
          'categoria': categoriaSeleccionada,
          'descripcion': descController.text,
          'nroRemito': remitoController.text,
          'proveedorId': proveedorId,
          'metodoPago': esDeuda ? 'pendiente' : metodoPago,
          'estado': 'pagado',
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Gasto registrado correctamente")),
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
