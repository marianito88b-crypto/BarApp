import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/services/dashboard/dashboard_filter_utils.dart';
import 'package:barapp/services/dashboard/dashboard_payment_resolver.dart';
import 'package:barapp/services/printer/printer_service.dart';

import 'dashboard_payment_helper.dart';

/// Tabla de ventas recientes para vista desktop.
class RecentSalesTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> salesDocs;
  final String filtro;
  final String? placeId;

  const RecentSalesTable({
    super.key,
    required this.salesDocs,
    required this.filtro,
    this.placeId,
  });

  void _modalDetalleProductos(
      BuildContext context, Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Productos del Pedido",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (item) => ListTile(
                  leading: Text(
                    "${item['cantidad']}x",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  title: Text(
                    item['nombre'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    "\$${item['precio'] * item['cantidad']}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirTicket(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    try {
      // Mostrar feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enviando a impresora..."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orangeAccent,
        ),
      );

      // Asegurar que el ID del documento esté en los datos
      final datosConId = Map<String, dynamic>.from(data);
      if (!datosConId.containsKey('id')) {
        datosConId['id'] = doc.id;
      }

      // Llamar al servicio de impresión
      await PrinterService().printTicket(datosConId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al imprimir: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = salesDocs
        .where(
          (doc) =>
              DashboardFilterUtils.matchFiltro(doc: doc, filtro: filtro),
        )
        .toList();

    final displayDocs = filteredDocs.take(15).toList();

    if (displayDocs.isEmpty) {
      return Center(
        child: Text(
          "No hay registros con filtro: $filtro",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Hora")),
          DataColumn(label: Text("Canal")),
          DataColumn(label: Text("Pago")),
          DataColumn(label: Text("Envío")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Detalle")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: displayDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final double tEnvio = (data['totalEnvio'] as num? ?? 0).toDouble();
          final payment = DashboardPaymentResolver.resolve(data);
          final metodo = payment.label;
          final colorPago = payment.color;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  DateFormat("HH:mm").format((data['fecha'] as Timestamp).toDate()),
                ),
              ),
              DataCell(Text(data['mesa'] ?? 'App-Bar')),
              DataCell(
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => mostrarDetallePago(
                    context,
                    data,
                    placeId: placeId,
                    orderId: data['orderId'] as String?,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorPago.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          metodo,
                          style: TextStyle(
                            color: colorPago,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (payment.method == PaymentMethod.mixto) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more,
                            size: 12,
                            color: Colors.white54,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  tEnvio > 0 ? "\$${tEnvio.toStringAsFixed(0)}" : "-",
                  style: const TextStyle(color: Colors.purpleAccent),
                ),
              ),
              DataCell(
                Text(
                  "\$${data['total']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 18,
                    color: Colors.orangeAccent,
                  ),
                  onPressed: () => _modalDetalleProductos(context, data),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.print,
                    size: 18,
                    color: Colors.orangeAccent,
                  ),
                  onPressed: () => _imprimirTicket(context, doc, data),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
