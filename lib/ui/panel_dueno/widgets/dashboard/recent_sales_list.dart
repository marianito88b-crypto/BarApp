import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/services/dashboard/dashboard_filter_utils.dart';
import 'package:barapp/services/dashboard/dashboard_payment_resolver.dart';
import 'package:barapp/services/printer/printer_service.dart';

import 'dashboard_payment_helper.dart';

/// Lista de ventas recientes para vista móvil.
class RecentSalesList extends StatelessWidget {
  final List<QueryDocumentSnapshot> salesDocs;
  final String filtro;
  final String? placeId;

  const RecentSalesList({
    super.key,
    required this.salesDocs,
    required this.filtro,
    this.placeId,
  });

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
        .where((doc) =>
            DashboardFilterUtils.matchFiltro(doc: doc, filtro: filtro))
        .toList();

    final displayDocs = filteredDocs.take(10).toList();

    if (displayDocs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          "No hay cobros con $filtro hoy.",
          style: const TextStyle(color: Colors.white24),
        ),
      );
    }

    return Column(
      children: displayDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final String origen = (data['origen'] ?? 'local').toString();
        final bool esApp = origen == 'app';
        final bool esExterno = origen == 'externo';

        final List<dynamic> pagos = data['pagos'] ?? [];
        final double totalDoc = (data['total'] as num).toDouble();

        String metodoDetectado =
            (data['metodoPrincipal'] ?? data['metodoPago'] ?? '')
                .toString()
                .toLowerCase();
        if (metodoDetectado.isEmpty && pagos.isNotEmpty) {
          metodoDetectado = (pagos.first['metodo'] ?? '').toString().toLowerCase();
        }
        if (pagos.length > 1) metodoDetectado = 'mixto';

        final payment = DashboardPaymentResolver.resolve(data);
        final colorMetodo = payment.color;
        final iconMetodo = payment.icon;

        double montoAMostrar = 0;
        String textoMonto = "";

        if (filtro == 'TODOS') {
          montoAMostrar = totalDoc;
          textoMonto =
              "\$${NumberFormat("#,##0", "es_AR").format(montoAMostrar)}";
        } else {
          for (var p in pagos) {
            String m = (p['metodo'] ?? '').toString().toLowerCase();
            bool match = false;
            if (filtro == 'MERCADOPAGO') {
              match = m.contains('qr') || m.contains('mercado');
            } else if (filtro == 'TRANSFERENCIA') {
              match = m.contains('transf');
            } else {
              match = m.contains(filtro.toLowerCase());
            }

            if (match) montoAMostrar += (p['monto'] as num).toDouble();
          }
          if (montoAMostrar == 0 && pagos.isEmpty) montoAMostrar = totalDoc;
          textoMonto =
              "\$${NumberFormat("#,##0", "es_AR").format(montoAMostrar)}";
          if (montoAMostrar < totalDoc) textoMonto += " (parcial)";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorMetodo.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => mostrarDetallePago(
              context,
              data,
              placeId: placeId,
              orderId: data['orderId'] as String?,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      esApp
                          ? Icons.phone_iphone
                          : (esExterno
                              ? Icons.motorcycle
                              : Icons.table_restaurant),
                      color: esApp
                          ? Colors.purpleAccent
                          : (esExterno
                              ? Colors.orangeAccent
                              : Colors.white54),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esApp
                              ? "Pedido Web"
                              : (esExterno
                                  ? "${data['canal'] ?? 'Venta Externa'}"
                                  : "Mesa ${data['mesa']}"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat("HH:mm").format(
                              (data['fecha'] as Timestamp).toDate()),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconMetodo, size: 14, color: colorMetodo),
                          const SizedBox(width: 6),
                          Text(
                            textoMonto,
                            style: TextStyle(
                              color: colorMetodo,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if ((data['totalEnvio'] as num? ?? 0) > 0)
                        const Text(
                          "+ ENVÍO",
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (filtro != 'TODOS' && montoAMostrar < totalDoc)
                        Text(
                          "de \$${NumberFormat("#,##0", "es_AR").format(totalDoc)}",
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      if (payment.method == PaymentMethod.mixto)
                        const Text(
                          "Ver detalle de pago",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.print,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    onPressed: () => _imprimirTicket(context, doc, data),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
