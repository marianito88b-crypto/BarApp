import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tarjeta de top productos vendidos hoy.
class TopProductsCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> salesDocs;
  final double? height;

  const TopProductsCard({
    super.key,
    required this.salesDocs,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Builder(
        builder: (context) {
          if (salesDocs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no hay platos vendidos hoy",
                style: TextStyle(color: Colors.white24),
              ),
            );
          }
          final Map<String, int> productCounts = {};
          for (var doc in salesDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['items'] != null) {
              for (var item in data['items']) {
                final String name = item['nombre'] ?? 'Desconocido';
                final int qty = (item['cantidad'] ?? 1) as int;
                productCounts[name] = (productCounts[name] ?? 0) + qty;
              }
            }
          }
          var sortedEntries = productCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          var topProducts = sortedEntries.take(5).toList();
          if (topProducts.isEmpty) {
            return const Center(
              child: Text(
                "Sin detalles de items",
                style: TextStyle(color: Colors.white24),
              ),
            );
          }
          int maxVal = topProducts.first.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topProducts.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${entry.value} un.",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: entry.value / maxVal,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: entry.value == maxVal
                                  ? Colors.greenAccent
                                  : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
