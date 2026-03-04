import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/pos/product_card.dart';
import '../../widgets/pos/category_header.dart';
import '../../widgets/pos/cart_panel.dart';

/// Layout móvil para la pantalla de toma de pedidos
class TomaPedidoMobileLayout extends StatelessWidget {
  final String placeId;
  final String mesaId;
  final String mesaNombre;
  final List<Map<String, dynamic>> pedidoHistorico;
  final List<Map<String, dynamic>> pedidoNuevo;
  final double totalGeneral;
  final bool guardando;
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final Function(Map<String, dynamic>) onAgregarProducto;
  final Function(int) onRestarProducto;
  final Function(Map<String, dynamic>) onEliminarItemHistorico;
  final VoidCallback onMarcharPedido;
  final VoidCallback onImprimirComandaCocina;
  final VoidCallback onImprimirCuentaCliente;
  final VoidCallback onCobrarCuenta;
  final VoidCallback onLiberarMesa;
  final Stream<QuerySnapshot> menuStream;
  final Stream<DocumentSnapshot> mesaStream;

  const TomaPedidoMobileLayout({
    super.key,
    required this.placeId,
    required this.mesaId,
    required this.mesaNombre,
    required this.pedidoHistorico,
    required this.pedidoNuevo,
    required this.totalGeneral,
    required this.guardando,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onAgregarProducto,
    required this.onRestarProducto,
    required this.onEliminarItemHistorico,
    required this.onMarcharPedido,
    required this.onImprimirComandaCocina,
    required this.onImprimirCuentaCliente,
    required this.onCobrarCuenta,
    required this.onLiberarMesa,
    required this.menuStream,
    required this.mesaStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildBuscador(),
          Expanded(child: _buildProductList(context)),
          _buildMobileBottomBar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mesa: $mesaNombre",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            pedidoHistorico.isNotEmpty ? "OCUPADA" : "ABRIENDO",
            style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onBusquedaChanged,
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: menuStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        var docs = snap.data!.docs;

        if (busqueda.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final nombre = data['nombre'].toString().toLowerCase();
            return nombre.contains(busqueda);
          }).toList();

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
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
              return ProductCard(
                doc: doc,
                isGrid: false,
                onTap: () {
                  onAgregarProducto(data);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Agregado: ${data['nombre']}"),
                      duration: const Duration(milliseconds: 600),
                      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.8),
                    ),
                  );
                },
              );
            },
          );
        }

        Map<String, List<DocumentSnapshot>> groupedMenu = {};
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String cat = data['categoria'] ?? 'Varios';
          if (cat.isNotEmpty) cat = cat[0].toUpperCase() + cat.substring(1);

          if (!groupedMenu.containsKey(cat)) groupedMenu[cat] = [];
          groupedMenu[cat]!.add(doc);
        }

        final categories = groupedMenu.keys.toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: CustomScrollView(
            slivers: [
              for (var category in categories) ...[
                SliverToBoxAdapter(
                  child: CategoryHeader(title: category),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final doc = groupedMenu[category]![i];
                      final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductCard(
                          doc: doc,
                          isGrid: false,
                          onTap: () {
                            onAgregarProducto(data);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Agregado: ${data['nombre']}"),
                                duration: const Duration(milliseconds: 600),
                                backgroundColor:
                                    Colors.orangeAccent.withValues(alpha: 0.8),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: groupedMenu[category]!.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 25)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileBottomBar(BuildContext context) {
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
                "Total Mesa",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                "\$${totalGeneral.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 20,
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
            onPressed: () => _mostrarBottomSheetCarrito(context),
            icon: const Icon(Icons.list_alt),
            label: const Text("VER PEDIDO"),
          ),
        ],
      ),
    );
  }

  void _mostrarBottomSheetCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: CartPanel(
                    placeId: placeId,
                    mesaId: mesaId,
                    pedidoNuevo: pedidoNuevo,
                    pedidoHistorico: pedidoHistorico,
                    totalGeneral: totalGeneral,
                    guardando: guardando,
                    mesaStream: mesaStream,
                    onRestarProducto: onRestarProducto,
                    onEliminarItemHistorico: onEliminarItemHistorico,
                    onMarcharPedido: onMarcharPedido,
                    onImprimirComandaCocina: onImprimirComandaCocina,
                    onImprimirCuentaCliente: onImprimirCuentaCliente,
                    onCobrarCuenta: onCobrarCuenta,
                    onLiberarMesa: onLiberarMesa,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
