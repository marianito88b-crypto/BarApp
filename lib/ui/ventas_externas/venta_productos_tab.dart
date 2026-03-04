import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/ventas_externas/modal_checkout_venta_externa.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_product_tile.dart';
import 'package:barapp/ui/panel_dueno/logic/ventas_externas_logic.dart';

class VentaProductosTab extends StatefulWidget {
  final String placeId;
  const VentaProductosTab({super.key, required this.placeId});

  @override
  State<VentaProductosTab> createState() => _VentaProductosTabState();
}

class _VentaProductosTabState extends State<VentaProductosTab>
    with VentaExternaCartMixin {

  late final Stream<QuerySnapshot> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('menu')
        .orderBy('categoria')
        .snapshots();
  }
 
  // =========================================================
  // 📦 SELECTOR DE PRODUCTOS
  // =========================================================
  Widget _buildProductSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        final docs = snapshot.data!.docs;

        Map<String, List<DocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = (data['categoria'] ?? 'Varios').toString();
          grouped.putIfAbsent(cat, () => []).add(doc);
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return ExternaProductTile(
                    product: data,
                    onTap: () => agregarProducto(data),
                  );
                }),
              ],
            );
          }).toList(),
        );
      },
    );
  }


  // =========================================================
  // 🛒 CARRITO
  // =========================================================
  Widget _buildCarrito() {
    if (cart.isEmpty) return const SizedBox.shrink();

    return Column(
      children: cart.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;

        return ListTile(
          dense: true,
          title: Text(
            "${item['cantidad']}x ${item['nombre']}",
            style: const TextStyle(color: Colors.white),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
            onPressed: () => restarProducto(i),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // 🧱 UI
  // =========================================================
 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF121212),
    body: Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildProductSelector()),
              const Divider(color: Colors.white12),
              _buildCarrito(),
            ],
          ),
        ),

        // 💰 TOTAL + COBRO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL",
                      style: TextStyle(color: Colors.white70)),
                  Text(
                    "\$${cartTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.attach_money),
                label: const Text(
                  "CONTINUAR",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: cart.isEmpty
                    ? null
                    : () => _abrirCheckout(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  /// Abre el modal de checkout y maneja el resultado
  Future<void> _abrirCheckout() async {
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ModalCheckoutVentaExterna(
          placeId: widget.placeId,
          items: List.from(cart), // Copia de la lista
          total: cartTotal,
        ),
      );

      if (ok == true && mounted) {
        limpiarCarrito();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Venta registrada y stock actualizado"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error abriendo checkout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
