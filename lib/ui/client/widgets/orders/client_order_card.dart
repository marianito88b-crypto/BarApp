import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_status_stepper.dart';
import 'payment_info_dialog.dart';
import 'delivery_rating_dialog.dart';

/// Widget que representa una tarjeta de pedido del cliente
/// 
/// Muestra información del pedido, items, estado y botones de acción.
class ClientOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onSendReceipt;

  const ClientOrderCard({
    super.key,
    required this.data,
    this.onSendReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['estado'] ?? 'pendiente';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
    final fecha =
        timestamp != null ? DateFormat('dd/MM • HH:mm').format(timestamp) : '';
    final driverName = data['driverName'];
    final placeName = data['placeName'] ?? "Restaurante";

    // Datos de pago
    final metodoPago = (data['metodoPago'] ?? 'efectivo').toString().toLowerCase();
    final placeId = data['placeId']?.toString();

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        fecha,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\$${NumberFormat("#,##0", "es_AR").format(total)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // ITEMS
            ...items.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          "${item['cantidad']}x ",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (item['nombre'] ?? 'Producto').toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "+ ${items.length - 3} items más...",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // BARRA DE ESTADO
            OrderStatusStepper(
              status: status,
              driverName: driverName,
            ),

            // Botón de Confirmar Recepción (solo cuando está entregado)
            if (status == 'entregado' && data['rating_entrega'] == null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final orderId = data['id'] ?? '';
                    if (orderId.isNotEmpty && placeId != null) {
                      showDialog(
                        context: context,
                        builder: (_) => DeliveryRatingDialog(
                          orderId: orderId,
                          placeId: placeId.toString(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text(
                    "Confirmar Recepción y Calificar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],

            // Botones de acción para transferencia
            if (metodoPago == 'transferencia' &&
                status != 'rechazado' &&
                status != 'entregado') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // 1. Ver Datos
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (placeId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No se pudo obtener la información del local",
                              ),
                            ),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (_) => ClientPaymentInfoDialog(
                            placeId: placeId,
                            total: total,
                          ),
                        );
                      },
                      child: const Text(
                        "Ver Datos",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 2. Enviar Comprobante (WhatsApp)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text(
                        "Comprobante",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: onSendReceipt,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
