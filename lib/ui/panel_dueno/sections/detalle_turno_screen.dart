import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetalleTurnoScreen extends StatefulWidget {
  final String placeId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String responsable;

  const DetalleTurnoScreen({
    super.key,
    required this.placeId,
    required this.fechaInicio,
    this.fechaFin,
    required this.responsable,
  });

  @override
  State<DetalleTurnoScreen> createState() => _DetalleTurnoScreenState();
}

class _DetalleTurnoScreenState extends State<DetalleTurnoScreen> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    // Si fechaFin es null (turno abierto), usamos Now
    final DateTime end = widget.fechaFin ?? DateTime.now();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('ventas')
        .where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fechaInicio),
        )
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Tickets del Turno",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No hubo ventas en este turno.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final total = (data['total'] ?? 0).toDouble();
              final Timestamp ts = data['fecha'];
              final String mesa = data['mesa'] ?? 'Mesa';

              // Ver items
              String itemsResumen = "";
              if (data['items'] != null) {
                final items = data['items'] as List;
                itemsResumen = items
                    .map((e) => "${e['cantidad']}x ${e['nombre']}")
                    .join(", ");
              }

              final List pagos = data['pagos'] ?? [];
              String metodoStr = "Efectivo";

              if (pagos.isNotEmpty) {
                metodoStr = pagos.length > 1
                    ? "Mixto"
                    : pagos.first['metodo'].toString().toUpperCase();
              } else {
                final m = (data['metodoPrincipal'] ??
                        data['metodoPago'] ??
                        'Efectivo')
                    .toString()
                    .toUpperCase();
                metodoStr = m;
              }

              // Pequeño hack visual para que "TRANSFERENCIA" no quede tan largo
              if (metodoStr.contains("TRANSF")) metodoStr = "TRANSFERENCIA";

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt,
                    color: Colors.orangeAccent,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mesa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${NumberFormat('#,##0').format(total)}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateFormat("HH:mm:ss").format(ts.toDate())} • $metodoStr",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        itemsResumen,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
