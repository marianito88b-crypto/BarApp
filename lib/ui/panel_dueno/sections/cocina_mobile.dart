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

class _CocinaMobileState extends State<CocinaMobile> with KitchenLogicMixin, SingleTickerProviderStateMixin {
  @override
  String get placeId => widget.placeId;

  late TabController _tabController;
  late final Stream<QuerySnapshot> _pendientesStream;
  late final Stream<QuerySnapshot> _historialStream;

  @override
  void initState() {
    super.initState();
    initKitchenLogic();
    _tabController = TabController(length: 2, vsync: this);

    _pendientesStream = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("orders")
        .where('estado', whereIn: ['en_preparacion', 'pendiente', 'cancelado_por_mozo'])
        .orderBy('createdAt', descending: false)
        .snapshots();

    const int horaCorte = 6;
    final now = DateTime.now();
    final DateTime startOfDay = now.hour < horaCorte
        ? DateTime(now.year, now.month, now.day, horaCorte, 0, 0).subtract(const Duration(days: 1))
        : DateTime(now.year, now.month, now.day, horaCorte, 0, 0);

    _historialStream = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("orders")
        .where('estado', whereIn: [
          'listo', 'preparado', 'listo_para_retirar', 'entregado', 'archivado',
        ])
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          preferredSize: const Size.fromHeight(94),
          child: Column(
            children: [
              KitchenStatusBar(placeId: widget.placeId),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.orangeAccent,
                labelColor: Colors.orangeAccent,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: "Pendientes", icon: Icon(Icons.pending_actions, size: 18)),
                  Tab(text: "Historial de Hoy", icon: Icon(Icons.history, size: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendientesTab(),
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildPendientesTab() {
    return StreamBuilder<QuerySnapshot>(
        stream: _pendientesStream,
        builder: (context, snap) {
          // Error handling (e.g. missing composite index)
          if (snap.hasError) {
            debugPrint('❌ Error pendientes stream: ${snap.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error cargando comandas:\n${snap.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

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
      );
  }

  Widget _buildHistorialTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _historialStream,
      builder: (context, snap) {
        // Error handling (e.g. missing composite index)
        if (snap.hasError) {
          debugPrint('❌ Error historial stream: ${snap.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando historial:\n${snap.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return _buildLoadingState();
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  "Sin comandas en el historial de hoy",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return _buildHistorialList(docs);
      },
    );
  }

  Widget _buildHistorialList(List<DocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final estado = data['estado'] ?? '';
        final bool cancelado = estado == 'cancelado_por_mozo' || estado == 'archivado';
        final Timestamp? ts = data['createdAt'] ?? data['timestamp'];
        final String hora = ts != null
            ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
            : '--:--';
        final ident = data['mesaNombre'] ?? data['clienteNombre'] ?? 'Anónimo';
        final estadoLabel = cancelado ? 'CANCELADO' : (estado == 'entregado' ? 'ENTREGADO' : 'DESPACHADO');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1E1E1E),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$ident · $hora",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cancelado
                            ? Colors.redAccent.withValues(alpha: 0.3)
                            : Colors.greenAccent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoLabel,
                        style: TextStyle(
                          color: cancelado ? Colors.redAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...items.take(5).map((item) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text(
                        "${item['cantidad']}x ${item['nombre']}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    )),
                if (items.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      "+ ${items.length - 5} más",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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