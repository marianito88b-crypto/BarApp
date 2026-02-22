import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/cocina/comanda_ticket.dart';
import '../widgets/cocina/kitchen_status_bar.dart';
import '../logic/kitchen_logic.dart';

class CocinaMobile extends StatefulWidget {
  final String placeId;
  const CocinaMobile({super.key, required this.placeId});

  @override
  State<CocinaMobile> createState() => _CocinaMobileState();
}

class _CocinaMobileState extends State<CocinaMobile> with KitchenLogicMixin {
  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    initKitchenLogic();
  }

  @override
  void dispose() {
    disposeKitchenLogic();
    super.dispose();
  }

  // ===========================================================================
  // 🖥️ BUILD UI - ORQUESTADOR DEL STREAMBUILDER
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.soup_kitchen, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Monitor de Cocina (KDS)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: KitchenStatusBar(placeId: widget.placeId),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("places")
            .doc(widget.placeId)
            .collection("orders")
            .where('estado', whereIn: ['en_preparacion', 'pendiente'])
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snap) {
          // Estado de carga
          if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
            return _buildLoadingState();
          }

          final docs = snap.data!.docs;

          // Estado vacío
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          // Estado con comandas - Grid responsivo
          return _buildComandasGrid(docs);
        },
      ),
    );
  }

  /// Construye el estado visual de carga
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.orangeAccent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Cargando comandas...",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el estado visual cuando no hay comandas
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 120,
              color: Colors.greenAccent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "¡Cocina al día!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No hay comandas pendientes",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el grid de comandas con cálculo responsivo de columnas
  Widget _buildComandasGrid(List<DocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cálculo inteligente de columnas según el ancho disponible
        int crossAxisCount;
        if (constraints.maxWidth < 600) {
          // Celulares pequeños: 1 columna
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          // Celulares grandes: 2 columnas
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          // Tablets: 3 columnas
          crossAxisCount = 3;
        } else {
          // Tablets grandes/Desktop: 4+ columnas (máximo 4 para legibilidad)
          crossAxisCount = 4;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) => ComandaTicket(
            doc: docs[i],
            placeId: widget.placeId,
          ),
        );
      },
    );
  }
}