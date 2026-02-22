import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pos_utils.dart';

/// Panel de comanda (carrito) con estilo Cyberpunk/Dark
/// 
/// Muestra los productos nuevos y los ya marchados,
/// con acciones para marchar, imprimir, cobrar y liberar mesa.
class CartPanel extends StatelessWidget {
  final String placeId;
  final String mesaId;
  final List<Map<String, dynamic>> pedidoNuevo;
  final List<Map<String, dynamic>> pedidoHistorico;
  final double totalGeneral;
  final bool guardando;
  final Function(int index) onRestarProducto;
  final Function(Map<String, dynamic> item) onEliminarItemHistorico;
  final VoidCallback onMarcharPedido;
  final VoidCallback onImprimirComandaCocina;
  final VoidCallback onImprimirCuentaCliente;
  final VoidCallback onCobrarCuenta;
  final VoidCallback onLiberarMesa;

  const CartPanel({
    super.key,
    required this.placeId,
    required this.mesaId,
    required this.pedidoNuevo,
    required this.pedidoHistorico,
    required this.totalGeneral,
    required this.guardando,
    required this.onRestarProducto,
    required this.onEliminarItemHistorico,
    required this.onMarcharPedido,
    required this.onImprimirComandaCocina,
    required this.onImprimirCuentaCliente,
    required this.onCobrarCuenta,
    required this.onLiberarMesa,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId)
          .snapshots(),
      builder: (context, mesaSnap) {
        final mesaData = mesaSnap.data?.data();
        final estadoMesa = (mesaData != null && mesaData is Map<String, dynamic>) 
            ? (mesaData['estado'] as String? ?? 'libre')
            : 'libre';
        final bool mesaPagada = estadoMesa == 'pagada';
        
        return Container(
          color: const Color(0xFF151515),
          child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            width: double.infinity,
            child: const Text(
              "Comanda Actual",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (pedidoNuevo.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "MARCHANDO...",
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...pedidoNuevo.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${item['cantidad']}x ${item['nombre']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => onRestarProducto(idx),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: guardando ? null : onMarcharPedido,
                      icon: const Icon(Icons.soup_kitchen),
                      label: guardando
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text("MARCHAR A COCINA (GUARDAR)"),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: guardando ? null : onImprimirComandaCocina,
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text("IMPRIMIR COMANDA (PAPEL)"),
                    ),
                  ),
                  
                  const Divider(color: Colors.white24, height: 30),
                ],

                if (pedidoHistorico.isEmpty && pedidoNuevo.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        "Sin pedidos aún",
                        style: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                
                if (pedidoHistorico.isNotEmpty) ...[
                  const Text(
                    "YA MARCHADOS",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...pedidoHistorico.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${item['cantidad']}x ${item['nombre']}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "\$${(PosUtils.safeDouble(item['precio']) * PosUtils.safeInt(item['cantidad'])).toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onEliminarItemHistorico(item),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${totalGeneral.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (totalGeneral > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: guardando ? null : onImprimirCuentaCliente,
                      icon: const Icon(Icons.receipt_long, color: Colors.orangeAccent),
                      label: const Text("IMPRIMIR CUENTA (PRECIOS)"),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (totalGeneral > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: guardando ? null : onCobrarCuenta,
                      icon: const Icon(Icons.attach_money),
                      label: const Text(
                        "COBRAR (FINALIZAR)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: onLiberarMesa,
                      icon: const Icon(Icons.door_back_door_outlined),
                      label: const Text("LIBERAR MESA"),
                    ),
                  ),
                
                // Botón adicional para liberar mesa cuando está pagada (incluso con total > 0)
                // Esto permite liberar la mesa manualmente después de cobrar
                if (mesaPagada && totalGeneral > 0) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: guardando ? null : onLiberarMesa,
                      icon: const Icon(Icons.door_back_door_outlined),
                      label: const Text("LIBERAR MESA"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
