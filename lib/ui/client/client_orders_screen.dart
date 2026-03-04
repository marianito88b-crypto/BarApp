import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'widgets/orders/client_order_card.dart';
import 'logic/orders_logic.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: Text("Inicia sesión para ver tus pedidos", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Mis Pedidos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "EN CURSO"),
            Tab(text: "HISTORIAL"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserOrdersList(userId: user.uid, active: true),
          _UserOrdersList(userId: user.uid, active: false),
        ],
      ),
    );
  }
}

class _UserOrdersList extends StatefulWidget {
  final String userId;
  final bool active;

  const _UserOrdersList({
    required this.userId,
    required this.active,
  });

  @override
  State<_UserOrdersList> createState() => _UserOrdersListState();
}

class _UserOrdersListState extends State<_UserOrdersList>
    with ClientOrdersLogicMixin {
  late final Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = getOrdersStream(widget.userId, widget.active);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint("Error ClientOrders: ${snap.error}");
          return const Center(
            child: Text(
              "Error cargando pedidos",
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.active ? Icons.fastfood_outlined : Icons.history,
                  size: 80,
                  color: Colors.white10,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.active
                      ? "No tienes pedidos en curso"
                      : "No tienes historial aún",
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // Inyección de datos críticos
            data['id'] = doc.id;
            data['placeId'] =
                data['placeId'] ?? doc.reference.parent.parent!.id;

            return ClientOrderCard(
              data: data,
              onSendReceipt: () {
                fetchAndOpenWhatsapp(data['placeId'], data);
              },
            );
          },
        );
      },
    );
  }
}
