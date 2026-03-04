import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/delivery/order_delivery_card.dart';
import '../logic/delivery_logic.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  final String placeId;
  const DeliveryOrdersScreen({super.key, required this.placeId});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin, DeliveryLogicMixin {
  late TabController _tabController;

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Gestión de Pedidos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [Tab(text: "EN PROCESO"), Tab(text: "HISTORIAL")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(
            placeId: widget.placeId,
            isActive: true,
            ordersStream: getOrdersStream(isActive: true, userRol: 'admin'),
            driversStream: getDriversStream(),
          ),
          _OrdersList(
            placeId: widget.placeId,
            isActive: false,
            ordersStream: getOrdersStream(isActive: false, userRol: 'admin'),
            driversStream: getDriversStream(),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String placeId;
  final bool isActive;
  final Stream<QuerySnapshot> ordersStream;
  final Stream<QuerySnapshot> driversStream;
  
  const _OrdersList({
    required this.placeId,
    required this.isActive,
    required this.ordersStream,
    required this.driversStream,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Stream de Staff (Choferes)
    return StreamBuilder<QuerySnapshot>(
      stream: driversStream,
      builder: (context, driversSnap) {
        if (driversSnap.hasError) {
          debugPrint("Error cargando choferes: ${driversSnap.error}");
        }
        
        final List<QueryDocumentSnapshot> availableDrivers =
            driversSnap.data?.docs ?? [];

        // 2. Stream de Pedidos usando el Mixin
        return StreamBuilder<QuerySnapshot>(
          stream: ordersStream,
          builder: (context, ordersSnap) {
            if (ordersSnap.hasError) {
              debugPrint("Error cargando pedidos: ${ordersSnap.error}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "Error al cargar pedidos",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${ordersSnap.error}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!ordersSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              );
            }

            // Ordenamiento seguro por fecha (más nuevo arriba)
            final docs = ordersSnap.data!.docs.toList();
            docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              
              final ta = dataA['createdAt'] as Timestamp?;
              final tb = dataB['createdAt'] as Timestamp?;
              
              if (ta == null) return 1;
              if (tb == null) return -1;
              
              return tb.compareTo(ta); // Orden descendente
            });

            if (docs.isEmpty) return _buildEmptyState();

            // Para el historial, agrupar por día con separadores visuales
            if (!isActive) {
              final List<dynamic> groupedItems = [];
              final now = DateTime.now();
              final yesterday = now.subtract(const Duration(days: 1));
              String? currentDay;
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                final date = ts?.toDate();
                final String dayLabel;
                if (date == null) {
                  dayLabel = 'Sin fecha';
                } else {
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  final isYesterday = date.year == yesterday.year &&
                      date.month == yesterday.month &&
                      date.day == yesterday.day;
                  if (isToday) {
                    dayLabel = 'Hoy — ${DateFormat('dd/MM/yyyy').format(date)}';
                  } else if (isYesterday) {
                    dayLabel = 'Ayer — ${DateFormat('dd/MM/yyyy').format(date)}';
                  } else {
                    dayLabel = DateFormat('dd/MM/yyyy').format(date);
                  }
                }
                if (dayLabel != currentDay) {
                  groupedItems.add(dayLabel);
                  currentDay = dayLabel;
                }
                groupedItems.add(doc);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedItems.length,
                itemBuilder: (context, index) {
                  final item = groupedItems[index];
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white12,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white12,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final doc = item as QueryDocumentSnapshot;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OrderDeliveryCard(
                      placeId: placeId,
                      docId: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                      availableDrivers: availableDrivers,
                      userRol: 'admin',
                      isDetailed: false,
                    ),
                  );
                },
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return OrderDeliveryCard(
                  placeId: placeId,
                  docId: doc.id,
                  data: doc.data() as Map<String, dynamic>,
                  availableDrivers: availableDrivers,
                  userRol: 'admin', // En esta pantalla siempre es admin
                  isDetailed: false, // Vista compacta
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.moped : Icons.history_toggle_off,
            size: 60,
            color: Colors.white12,
          ),
          const SizedBox(height: 10),
          Text(
            isActive ? "Todo tranquilo por ahora" : "Sin historial reciente",
            style: const TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
