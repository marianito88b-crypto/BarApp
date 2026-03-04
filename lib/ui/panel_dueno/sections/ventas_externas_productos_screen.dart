import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/ventas_externas/modal_checkout_venta_externa.dart';
import '../widgets/ventas_externas/externa_product_card.dart';
import '../widgets/ventas_externas/externa_cart_panel.dart';
import '../logic/ventas_externas_logic.dart';

class VentasExternasProductosScreen extends StatefulWidget {
  final String placeId;
  const VentasExternasProductosScreen({super.key, required this.placeId});

  @override
  State<VentasExternasProductosScreen> createState() =>
      _VentasExternasProductosScreenState();
}

class _VentasExternasProductosScreenState
    extends State<VentasExternasProductosScreen> with VentaExternaCartMixin {
  String _busqueda = '';
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

  // ===========================================================================
  // 🖥️ UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Venta externa con productos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildBuscador(),
          Expanded(child: _buildProductList()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E1E1E),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Buscar producto...",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent),
          filled: true,
          fillColor: Colors.black45,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _menuStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error al cargar el menú',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        var docs = snap.data!.docs;

        if (_busqueda.isNotEmpty) {
          docs =
              docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['nombre'].toString().toLowerCase().contains(
                  _busqueda,
                );
              }).toList();
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No se encontraron productos",
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => ExternaProductCard(
            doc: docs[i],
            onTap: () {
              final raw = docs[i].data() as Map<String, dynamic>;
              final data = {
                ...raw,
                'id': docs[i].id,
              };
              agregarProducto(data);
            },
          ),
        );
      },
    );
  }


  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Total",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                "\$${cartTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: cart.isEmpty ? null : () => _mostrarCarrito(context),
            icon: const Icon(Icons.list_alt),
            label: const Text("VER CARRITO"),
          ),
        ],
      ),
    );
  }

  void _mostrarCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return StatefulBuilder(
            builder: (context, modalSetState) {
              return ExternaCartPanel(
                pedido: cart,
                total: cartTotal,
                onRestarProducto: (index) {
                  modalSetState(() {
                    restarProducto(index);
                  });
                },
                onContinuar: () async {
                  // Pre-capturar antes del gap asíncrono
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final bool? ventaExitosa = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ModalCheckoutVentaExterna(
                      placeId: widget.placeId,
                      items: List.from(cart),
                      total: cartTotal,
                    ),
                  );

                  if (!mounted) return;
                  if (ventaExitosa == true) {
                    // 1️⃣ CERRAR EL CARRITO (Modal A)
                    navigator.pop();

                    // 2️⃣ LIMPIAR ESTADO GLOBAL (todo en un solo setState)
                    setState(() {
                      limpiarCarritoSinSetState();
                      _busqueda = '';
                    });

                    // 3️⃣ FEEDBACK VISUAL
                    messenger.showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white, size: 26),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Venta procesada correctamente",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
