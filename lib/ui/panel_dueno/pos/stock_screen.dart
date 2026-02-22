import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockScreen extends StatelessWidget {
  final String placeId;

  const StockScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Control de Stock 📦", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtramos solo los productos que SÍ controlan stock
        stream: FirebaseFirestore.instance
            .collection('places').doc(placeId)
            .collection('menu')
            .where('controlaStock', isEqualTo: true) 
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No hay productos con control de stock activado.", style: TextStyle(color: Colors.white54)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final stockActual = data['stock'] ?? 0;
              final docId = docs[i].id;

              return _StockCard(
                nombre: data['nombre'],
                stock: stockActual,
                onUpdate: (nuevoStock) {
                  // Actualizamos directo en Firebase
                  FirebaseFirestore.instance
                      .collection('places').doc(placeId)
                      .collection('menu').doc(docId)
                      .update({'stock': nuevoStock});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String nombre;
  final int stock;
  final Function(int) onUpdate;

  const _StockCard({required this.nombre, required this.stock, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    // Color semáforo según cantidad
    Color stockColor = Colors.greenAccent;
    if (stock < 10) stockColor = Colors.orangeAccent;
    if (stock <= 3) stockColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 14, color: stockColor),
                    const SizedBox(width: 6),
                    Text(
                      stock == 0 ? "SIN STOCK" : "$stock u.", 
                      style: TextStyle(color: stockColor, fontWeight: FontWeight.bold)
                    ),
                  ],
                )
              ],
            ),
          ),
          // Botones de ajuste rápido
          _BotonAjuste(icon: Icons.remove, onTap: () => onUpdate(stock > 0 ? stock - 1 : 0)),
          const SizedBox(width: 12),
          _BotonAjuste(icon: Icons.add, isPlus: true, onTap: () => onUpdate(stock + 1)),
          const SizedBox(width: 12),
          // Botón para entrada masiva (ej: llega un cajón de 12)
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.blueAccent),
            tooltip: "Ingreso Manual",
            onPressed: () => _mostrarDialogoIngreso(context),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoIngreso(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("Ingresar Stock: $nombre", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Cantidad a sumar (ej: 24)",
            labelStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.add, color: Colors.greenAccent),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () {
              final int ingreso = int.tryParse(controller.text) ?? 0;
              if (ingreso > 0) {
                onUpdate(stock + ingreso);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }
}

class _BotonAjuste extends StatelessWidget {
  final IconData icon;
  final bool isPlus;
  final VoidCallback onTap;

  const _BotonAjuste({required this.icon, this.isPlus = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPlus ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPlus ? Colors.greenAccent : Colors.redAccent),
        ),
        child: Icon(icon, color: isPlus ? Colors.greenAccent : Colors.redAccent, size: 20),
      ),
    );
  }
}