import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barapp/ui/panel_dueno/widgets/metrics/metrics_helpers.dart' as metrics;

/// Widget que muestra un gráfico de dona con la distribución de pagos
/// por método (Efectivo, Digital/QR, Transferencia)
class PaymentsDonutChart extends StatelessWidget {
  final double totalEfectivo;
  final double totalDigital;
  final double totalTransferencia;

  const PaymentsDonutChart({
    super.key,
    required this.totalEfectivo,
    required this.totalDigital,
    required this.totalTransferencia,
  });

  @override
  Widget build(BuildContext context) {
    double total = totalEfectivo + totalDigital + totalTransferencia;

    String pctEfectivo =
        total > 0 ? ((totalEfectivo / total) * 100).toStringAsFixed(0) : "0";
    String pctDigital =
        total > 0 ? ((totalDigital / total) * 100).toStringAsFixed(0) : "0";
    String pctTransf =
        total > 0
            ? ((totalTransferencia / total) * 100).toStringAsFixed(0)
            : "0";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DISTRIBUCIÓN DE PAGOS",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        if (totalEfectivo > 0)
                          PieChartSectionData(
                            value: totalEfectivo,
                            color: Colors.greenAccent,
                            radius: 18,
                            showTitle: false,
                            badgeWidget: metrics.Badge(
                              icon: Icons.money,
                              color: Colors.greenAccent,
                              text: "$pctEfectivo%",
                            ),
                            badgePositionPercentageOffset: 1.4,
                          ),
                        if (totalDigital > 0)
                          PieChartSectionData(
                            value: totalDigital,
                            color: Colors.blueAccent,
                            radius: 18,
                            showTitle: false,
                            badgeWidget: metrics.Badge(
                              icon: Icons.credit_card,
                              color: Colors.blueAccent,
                              text: "$pctDigital%",
                            ),
                            badgePositionPercentageOffset: 1.4,
                          ),
                        if (totalTransferencia > 0)
                          PieChartSectionData(
                            value: totalTransferencia,
                            color: Colors.purpleAccent,
                            radius: 18,
                            showTitle: false,
                            badgeWidget: metrics.Badge(
                              icon: Icons.account_balance,
                              color: Colors.purpleAccent,
                              text: "$pctTransf%",
                            ),
                            badgePositionPercentageOffset: 1.4,
                          ),
                        if (total == 0)
                          PieChartSectionData(
                            value: 1,
                            color: Colors.white10,
                            radius: 18,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      "\$${NumberFormat.compact().format(total)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // LEYENDAS
          Center(
            child: Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: [
                metrics.LegendItem(
                  color: Colors.greenAccent,
                  label: "Efectivo",
                  amount: totalEfectivo,
                ),
                metrics.LegendItem(
                  color: Colors.blueAccent,
                  label: "Digital/QR",
                  amount: totalDigital,
                ),
                metrics.LegendItem(
                  color: Colors.purpleAccent,
                  label: "Transf.",
                  amount: totalTransferencia,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
