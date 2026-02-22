import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarjeta que muestra la rendición de un chofer (repartidor)
/// 
/// Calcula y muestra los viajes realizados hoy y el monto total a pagar
class DriverRendicionCard extends StatelessWidget {
  final String placeId;
  final QueryDocumentSnapshot driverDoc;

  const DriverRendicionCard({
    super.key,
    required this.placeId,
    required this.driverDoc,
  });

  @override
  Widget build(BuildContext context) {
    final choferData = driverDoc.data() as Map<String, dynamic>;
    final String emailChofer = choferData['email'] ?? '';
    final String nombreMostrado = choferData['nombre'] ?? emailChofer;

    // Ajuste de fecha: Buscamos desde las 00:00 de hoy
    final now = DateTime.now();
    final inicioHoy = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .where('repartidor', isEqualTo: emailChofer)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
          .snapshots(),
      builder: (context, vSnap) {
        // Manejo de errores con logs claros
        if (vSnap.hasError) {
          final error = vSnap.error.toString();
          debugPrint("🔥 ERROR FIRESTORE en Rendición:");
          debugPrint("   Chofer: $emailChofer");
          debugPrint("   Error: $error");
          
          // Detectar si es error de índice faltante
          final isIndexError = error.contains('index') || 
                               error.contains('indexes') ||
                               error.contains('requires an index');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isIndexError 
                          ? "⚠️ Índice de Firebase faltante"
                          : "Error al cargar rendición",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isIndexError
                      ? "Crea un índice compuesto en Firebase Console:\n"
                        "Colección: ventas\n"
                        "Campos: repartidor (Ascending), fecha (Ascending)"
                      : "Error: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}",
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }

        double recaudadoEnvios = 0;
        int cantidadViajes = 0;

        if (vSnap.hasData) {
          final docsVentas = vSnap.data!.docs;
          cantidadViajes = docsVentas.length;
          for (var vDoc in docsVentas) {
            final vData = vDoc.data() as Map<String, dynamic>;
            recaudadoEnvios += (vData['totalEnvio'] as num? ?? 0).toDouble();
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cantidadViajes > 0
                  ? Colors.greenAccent.withValues(alpha: 0.3)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purpleAccent.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.motorcycle,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreMostrado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "$cantidadViajes viajes realizados hoy",
                      style: TextStyle(
                        color: cantidadViajes > 0
                            ? Colors.greenAccent
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\$${NumberFormat("#,##0", "es_AR").format(recaudadoEnvios)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const Text(
                    "A PAGAR",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
