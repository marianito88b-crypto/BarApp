import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/delivery/order_delivery_card.dart';
import '../widgets/delivery/driver_rendicion_card.dart';
import '../logic/delivery_logic.dart';

class DeliveryMobile extends StatefulWidget {
  final String placeId;
  final String userEmail; 
  final String userRol;   
  
  const DeliveryMobile({
    super.key, 
    required this.placeId, 
    required this.userEmail, 
    required this.userRol
  });

  @override
  State<DeliveryMobile> createState() => _DeliveryMobileState();
}

class _DeliveryMobileState extends State<DeliveryMobile>
    with SingleTickerProviderStateMixin, DeliveryLogicMixin {
  late TabController _tabController;

  // 🔥 FIX: Cachear streams para no recrear listeners en cada rebuild
  late final Stream<QuerySnapshot> _ordersStream;
  late final Stream<QuerySnapshot> _driversStream;

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.userRol == 'repartidor' ? 1 : 2, vsync: this);
    _ordersStream = getOrdersStream(
      isActive: true,
      userRol: widget.userRol,
      userEmail: widget.userEmail,
    );
    _driversStream = getDriversStream();
  }
  @override
void dispose() {
  _tabController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.userRol != 'repartidor';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text("Sistema Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          tabs: [
            const Tab(text: "PEDIDOS", icon: Icon(Icons.moped)),
            if (isAdmin) const Tab(text: "RENDICIÓN", icon: Icon(Icons.payments)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UnifiedOrdersList(
            placeId: widget.placeId,
            userEmail: widget.userEmail,
            userRol: widget.userRol,
            ordersStream: _ordersStream,
            driversStream: _driversStream,
          ),
          if (isAdmin) _RendicionFlotaList(
            placeId: widget.placeId,
          ),
        ],
      ),
    );
  }
}

class _UnifiedOrdersList extends StatelessWidget {
  final String placeId;
  final String userEmail;
  final String userRol;
  final Stream<QuerySnapshot> ordersStream;
  final Stream<QuerySnapshot> driversStream;

  const _UnifiedOrdersList({
    required this.placeId,
    required this.userEmail,
    required this.userRol,
    required this.ordersStream,
    required this.driversStream,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Stream de choferes
    return StreamBuilder<QuerySnapshot>(
      stream: driversStream,
      builder: (context, driversSnap) {
        final List<QueryDocumentSnapshot> drivers = driversSnap.data?.docs ?? [];

        // 2. Stream de pedidos activos
        return StreamBuilder<QuerySnapshot>(
          stream: ordersStream,
          builder: (context, ordersSnap) {
            if (ordersSnap.hasError) {
              debugPrint("Error cargando pedidos: ${ordersSnap.error}");
              return Center(
                child: Text(
                  "Error: ${ordersSnap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!ordersSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              );
            }

            final docs = ordersSnap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "Sin pedidos activos",
                  style: TextStyle(color: Colors.white24),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) => OrderDeliveryCard(
                placeId: placeId,
                docId: docs[i].id,
                data: docs[i].data() as Map<String, dynamic>,
                availableDrivers: drivers,
                userRol: userRol,
                isDetailed: true,
              ),
            );
          },
        );
      },
    );
  }
}

// 💰 RENDICIÓN DE CHOFERES (Solo para administradores)
// =============================================================================
class _RendicionFlotaList extends StatelessWidget {
  final String placeId;

  const _RendicionFlotaList({
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    // Stream propio — no comparte suscripción con el tab de pedidos.
    // Compartir un broadcast stream puede dejar el StreamBuilder en
    // ConnectionState.waiting indefinidamente si el stream ya emitió
    // su último evento antes de que este widget se suscribiera.
    final driversStream = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('staff')
        .where('rol', isEqualTo: 'repartidor')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: driversStream,
      builder: (context, staffSnap) {
        if (staffSnap.hasError) {
          debugPrint("🔥 ERROR al cargar repartidores: ${staffSnap.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Error al cargar repartidores",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${staffSnap.error}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!staffSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final choferes = staffSnap.data!.docs;
        if (choferes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.motorcycle, size: 60, color: Colors.white12),
                SizedBox(height: 16),
                Text(
                  "No hay repartidores activos",
                  style: TextStyle(color: Colors.white24),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: choferes.length,
          itemBuilder: (context, i) => DriverRendicionCard(
            placeId: placeId,
            driverDoc: choferes[i],
          ),
        );
      },
    );
  }
}