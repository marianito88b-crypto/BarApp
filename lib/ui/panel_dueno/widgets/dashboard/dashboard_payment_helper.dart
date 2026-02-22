import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/ui/panel_dueno/widgets/delivery/client_rating_dialog.dart';

/// Muestra el modal con el detalle de pago de una venta.
/// 
/// [context]: Contexto de la UI
/// [data]: Datos de la venta
/// [placeId]: ID del lugar (opcional, necesario para calificar cliente)
/// [orderId]: ID del pedido original (opcional, necesario para calificar cliente)
void mostrarDetallePago(
  BuildContext context,
  Map<String, dynamic> data, {
  String? placeId,
  String? orderId,
}) {
  List<dynamic> pagos = data['pagos'] ?? [];
  final double total = (data['total'] as num?)?.toDouble() ?? 0.0;
  final String mesa =
      data['mesa'] ?? (data['origen'] == 'app' ? 'Pedido Web' : 'S/D');
  final String? nota = data['nota'] as String?;
  final List<dynamic>? items = data['items'] as List?;
  final bool esVentaRapida = data['origen'] == 'externo' && 
                              items != null &&
                              items.isNotEmpty &&
                              items.first['id'] == 'GENERICO';

  if (pagos.isEmpty) {
    String metodoRespaldo =
        (data['metodoPrincipal'] ?? data['metodoPago'] ?? 'Efectivo')
            .toString();
    pagos = [
      {'metodo': metodoRespaldo, 'monto': total},
    ];
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Detalle de Cobro",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "Origen: $mesa",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "\$${NumberFormat("#,##0", "es_AR").format(total)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            ...pagos.map((p) {
              final String metodoPago =
                  (p['metodo'] ?? 'EFECTIVO').toString().toUpperCase();
              final double amt = (p['monto'] as num?)?.toDouble() ?? 0.0;
              final String tipo = p['tipo'] ?? 'comida';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      tipo == 'delivery' ? Icons.moped : Icons.fastfood,
                      color: tipo == 'delivery'
                          ? Colors.purpleAccent
                          : Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metodoPago,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          tipo == 'delivery'
                              ? "COSTO DE ENVÍO"
                              : "CONSUMO COMIDA",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "\$${NumberFormat("#,##0", "es_AR").format(amt)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Mostrar nota si existe y es una venta rápida
            if (nota != null && nota.isNotEmpty && esVentaRapida) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "NOTA:",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nota,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Botón para calificar cliente (solo para pedidos de app con orderId)
            if (data['origen'] == 'app' && orderId != null && placeId != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              _buildRateClientButton(ctx, data, placeId, orderId),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            "Cerrar",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    ),
  );
}

/// Botón para calificar al cliente desde el historial de ventas
Widget _buildRateClientButton(
  BuildContext context,
  Map<String, dynamic> data,
  String placeId,
  String orderId,
) {
  // Obtener userId del pedido original
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('orders')
        .doc(orderId)
        .get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const SizedBox.shrink();
      }

      final orderData = snapshot.data!.data() as Map<String, dynamic>?;
      if (orderData == null) return const SizedBox.shrink();

      final userId = orderData['userId'] as String?;
      final ratingCliente = orderData['rating_cliente'] as Map<String, dynamic>?;
      
      // Si no hay userId o ya tiene calificación, mostrar estado o nada
      if (userId == null || userId.isEmpty) {
        return const SizedBox.shrink();
      }
      
      // Si ya tiene calificación, mostrar indicador
      if (ratingCliente != null) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              SizedBox(width: 8),
              Text(
                "Cliente ya calificado",
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
        );
      }

      final clienteNombre = orderData['clienteNombre'] ?? data['cliente'] ?? 'Cliente';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  "Calificación Interna",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Esta calificación es solo para optimizar el servicio y trato con el cliente. No es pública.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.star),
                label: const Text(
                  "Calificar Cliente",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(context); // Cerrar modal de detalle
                  showDialog(
                    context: context,
                    builder: (_) => ClientRatingDialog(
                      userId: userId,
                      orderId: orderId,
                      placeId: placeId,
                      clienteNombre: clienteNombre.toString(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
