import 'package:flutter/material.dart';

/// Panel del carrito de ventas externas
/// 
/// Muestra el detalle del pedido con opción de eliminar items
/// y botón para continuar con el checkout
class ExternaCartPanel extends StatelessWidget {
  final List<Map<String, dynamic>> pedido;
  final double total;
  final Function(int index) onRestarProducto;
  final VoidCallback onContinuar;

  const ExternaCartPanel({
    super.key,
    required this.pedido,
    required this.total,
    required this.onRestarProducto,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Detalle del pedido",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedido.length,
              itemBuilder: (_, i) {
                final item = pedido[i];
                final subtotal = (item['precio'] as num).toDouble() *
                    (item['cantidad'] as int);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "${item['cantidad']}x ${item['nombre']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "\$${subtotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => onRestarProducto(i),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "\$${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: pedido.isEmpty ? null : onContinuar,
                  child: const Text(
                    "CONTINUAR",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
