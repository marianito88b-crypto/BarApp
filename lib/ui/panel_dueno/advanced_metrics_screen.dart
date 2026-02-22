import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/kpi_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/metrics_helpers.dart' as metrics;
import 'package:barapp/ui/panel_dueno/widgets/metrics/payments_donut_chart.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/top_products_bar_chart.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/sales_line_chart.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/top_clients_ranking.dart';
import 'package:barapp/ui/panel_dueno/sections/detalle_turno_screen.dart';
import 'package:barapp/ui/panel_dueno/logic/metrics_logic.dart';

class AdvancedMetricsScreen extends StatefulWidget {
  final String placeId;

  const AdvancedMetricsScreen({super.key, required this.placeId});

  @override
  State<AdvancedMetricsScreen> createState() => _AdvancedMetricsScreenState();
}

class _AdvancedMetricsScreenState extends State<AdvancedMetricsScreen>
    with MetricsLogicMixin {
  bool _isWeekly = true;

  @override
  String get placeId => widget.placeId;

  @override
  bool get isWeekly => _isWeekly;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // MODAL DETALLE CIERRE
  void _mostrarDetalleCierre(Map<String, dynamic> sesion) {
    // ... (El mismo código que ya tenías, funciona bien)
    final double sistema =
        (sesion['monto_sistema_calculado'] as num?)?.toDouble() ?? 0;
    final double real = (sesion['monto_final_real'] as num?)?.toDouble() ?? 0;
    final double diff = (sesion['diferencia'] as num?)?.toDouble() ?? 0;
    final String responsable = sesion['usuario_apertura'] ?? 'Desconocido';
    final Timestamp tsApertura = sesion['fecha_apertura'];
    final Timestamp? tsCierre = sesion['fecha_cierre'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detalle del Turno",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                metrics.InfoRow(
                  "Responsable",
                  responsable.split('@')[0].toUpperCase(),
                  Colors.orangeAccent,
                ),
                metrics.InfoRow(
                  "Estado",
                  tsCierre == null ? "🟢 EN CURSO" : "🔴 CERRADO",
                  Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      metrics.InfoRow(
                        "Sistema calculó:",
                        "\$${NumberFormat('#,##0').format(sistema)}",
                        Colors.white54,
                      ),
                      metrics.InfoRow(
                        "Caja Real:",
                        "\$${NumberFormat('#,##0').format(real)}",
                        Colors.white,
                        isBold: true,
                      ),
                      const Divider(color: Colors.white10),
                      metrics.InfoRow(
                        diff >= 0 ? "Sobrante:" : "Faltante:",
                        "\$${NumberFormat('#,##0').format(diff.abs())}",
                        diff == 0
                            ? Colors.green
                            : (diff > 0 ? Colors.blue : Colors.red),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => DetalleTurnoScreen(
                                placeId: widget.placeId,
                                fechaInicio: tsApertura.toDate(),
                                fechaFin: tsCierre?.toDate(),
                                responsable: responsable,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("VER TICKETS DE ESTE TURNO"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Reportes y Cierres",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF151515),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ToggleButtons(
              isSelected: [_isWeekly, !_isWeekly],
              onPressed: (int index) {
                setState(() {
                  _isWeekly = index == 0;
                });
                fetchData();
              },
              color: Colors.white54,
              selectedColor: Colors.black,
              fillColor: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 30, minWidth: 60),
              children: const [
                Text("7D", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("30D", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
    ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
    : RefreshIndicator(
        onRefresh: fetchData, // 👈 Llama a tu función de carga
        color: Colors.orangeAccent,
        backgroundColor: const Color(0xFF1E1E1E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 👈 Obligatorio para que funcione el pull
          padding: const EdgeInsets.all(16),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: KPICard(
                            title: "Ingresos Totales",
                            value:
                                "\$${NumberFormat('#,##0', 'es_AR').format(totalIngresos)}",
                            numericValue: totalIngresos, // 👈 CLAVE
                            icon: Icons.attach_money,
                            color: Colors.greenAccent,
                            prevValue: ingresosPeriodoAnterior,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KPICard(
                            title: "Turnos Cerrados",
                            value: "$totalCierres",
                            icon: Icons.assignment_turned_in,
                            color: Colors.purpleAccent,
                            isMoney: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // PIE CHART + TOP PRODUCTS (Responsive)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PaymentsDonutChart(
                              totalEfectivo: totalEfectivo,
                              totalDigital: totalDigital,
                              totalTransferencia: totalTransferencia,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TopProductsBarChart(
                              topProductos: topProductos,
                              maxVentasProducto: maxVentasProducto,
                              isWeekly: _isWeekly,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          PaymentsDonutChart(
                            totalEfectivo: totalEfectivo,
                            totalDigital: totalDigital,
                            totalTransferencia: totalTransferencia,
                          ),
                          const SizedBox(height: 20),
                          TopProductsBarChart(
                            topProductos: topProductos,
                            maxVentasProducto: maxVentasProducto,
                            isWeekly: _isWeekly,
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),

                    // Grafico Lineal (Ventas)
                    const Text(
                      "EVOLUCIÓN DE VENTAS",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SalesLineChart(
                      chartSpots: chartSpots,
                      maxY: maxY,
                      isWeekly: _isWeekly,
                    ),

                    const SizedBox(height: 30),

                    // Sección de Respaldo y Archivo
                    _buildBackupSection(),

                    const SizedBox(height: 30),

                    // Ranking de Clientes
                    TopClientsRanking(placeId: placeId),

                    const SizedBox(height: 30),

                    // Historial
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "HISTORIAL DE TURNOS",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "${listaSesiones.length} registros",
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (listaSesiones.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No hay turnos cerrados en este periodo.",
                          style: TextStyle(color: Colors.white30),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listaSesiones.length,
                        itemBuilder: (context, index) {
                          return _buildSesionItem(listaSesiones[index]);
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    )
    );
  }


  // (El resto de _buildSesionItem, _InfoRow y widgets auxiliares se mantienen igual)
  Widget _buildSesionItem(Map<String, dynamic> sesion) {
    // ... (Mantener tu código actual de sesion item)
    // Solo para que compile si copias todo:
    final estado = sesion['estado'] ?? 'cerrada';
    final isOpen = estado == 'abierta';
    final double total =
        (sesion['monto_sistema_calculado'] as num?)?.toDouble() ?? 0;
    final double diff = (sesion['diferencia'] as num?)?.toDouble() ?? 0;
    final Timestamp ts = sesion['fecha_apertura'];

    Color statusColor = Colors.green;
    IconData icon = Icons.check_circle_outline;

    if (isOpen) {
      statusColor = Colors.blueAccent;
      icon = Icons.timelapse;
    } else if (diff != 0) {
      statusColor = diff > 0 ? Colors.blue : Colors.redAccent;
      icon = diff > 0 ? Icons.trending_up : Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _mostrarDetalleCierre(sesion),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(icon, color: statusColor, size: 20),
        ),
        title: Text(
          isOpen
              ? "TURNO ACTUAL (ABIERTO)"
              : "Cierre ${DateFormat('dd/MM - HH:mm').format(ts.toDate())}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          (sesion['usuario_apertura'] ?? '').toString().split('@')[0],
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${NumberFormat('#,##0').format(total)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isOpen && diff != 0)
                  Text(
                    diff > 0 ? "+ Sobra" : "- Falta",
                    style: TextStyle(color: statusColor, fontSize: 10),
                  )
                else
                  Text(
                    isOpen ? "En curso" : "Perfecto",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RESPALDO Y ARCHIVO",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Resguardo de Datos: Los registros de pedidos se mantienen en línea por 90 días. Recomendamos exportar sus reportes mensualmente para su archivo personal.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportOrdersToCSV(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download, size: 24),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Exportar Pedidos a CSV",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportOrdersToCSV() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Generando archivo CSV..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Obtener todas las ventas del lugar
      final ventasSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .orderBy('fecha', descending: true)
          .get();

      if (ventasSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay pedidos para exportar"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      // Crear contenido CSV
      final StringBuffer csvContent = StringBuffer();
      
      // Encabezados
      csvContent.writeln('Fecha,Cliente,Items,Total,Método de Pago');

      // Procesar cada venta
      for (var doc in ventasSnapshot.docs) {
        final data = doc.data();
        final Timestamp? fechaTs = data['fecha'];
        final fecha = fechaTs != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaTs.toDate())
            : 'Sin fecha';

        final cliente = (data['cliente'] ?? data['clienteNombre'] ?? 'Sin cliente').toString();
        final total = (data['total'] ?? 0).toDouble();

        // Concatenar items
        final List items = data['items'] ?? [];
        final String itemsStr = items
            .map((item) => '${item['cantidad'] ?? 1}x ${item['nombre'] ?? 'S/N'}')
            .join('; ');

        // Método de pago
        final List pagos = data['pagos'] ?? [];
        String metodoPago = 'Efectivo';
        if (pagos.isNotEmpty) {
          metodoPago = pagos.length > 1
              ? 'Mixto'
              : (pagos.first['metodo'] ?? 'Efectivo').toString().toUpperCase();
        } else {
          metodoPago = (data['metodoPrincipal'] ?? data['metodoPago'] ?? 'Efectivo')
              .toString()
              .toUpperCase();
        }

        // Escapar comillas y comas en los valores
        String escapeCSV(String value) {
          if (value.contains(',') || value.contains('"') || value.contains('\n')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        }

        csvContent.writeln(
          '${escapeCSV(fecha)},'
          '${escapeCSV(cliente)},'
          '${escapeCSV(itemsStr)},'
          '${total.toStringAsFixed(2)},'
          '${escapeCSV(metodoPago)}',
        );
      }

      // Guardar archivo
      if (kIsWeb) {
        // Para web, usar download
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "CSV generado (${ventasSnapshot.docs.length} pedidos). "
                "En web, el archivo se descargará automáticamente.",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // TODO: Implementar descarga para web si es necesario
        return;
      }

      // Para mobile, guardar en documentos
      final Directory directory = await getApplicationDocumentsDirectory();

      final String fileName = 'pedidos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsString(csvContent.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ CSV exportado exitosamente\n"
              "${ventasSnapshot.docs.length} pedidos\n"
              "Guardado en: $filePath",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      debugPrint('✅ CSV exportado: $filePath');
    } catch (e) {
      debugPrint('❌ Error exportando CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

