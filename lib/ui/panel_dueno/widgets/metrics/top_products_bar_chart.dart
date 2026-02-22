import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget que muestra un gráfico de barras con los productos más vendidos
class TopProductsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> topProductos;
  final double maxVentasProducto;
  final bool isWeekly;

  const TopProductsBarChart({
    super.key,
    required this.topProductos,
    required this.maxVentasProducto,
    required this.isWeekly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOP ${isWeekly ? 5 : 10} PRODUCTOS",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: topProductos.isEmpty
                ? const Center(
                    child: Text(
                      "Sin datos",
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVentasProducto * 1.1,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String nombre =
                                topProductos[group.x.toInt()]['nombre'];
                            return BarTooltipItem(
                              "$nombre\n${rod.toY.toInt()} u.",
                              const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < topProductos.length) {
                                String nombre = topProductos[index]['nombre'];
                                // Truncamos nombre si es muy largo
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    nombre.length > 5
                                        ? "${nombre.substring(0, 4)}."
                                        : nombre,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: topProductos.asMap().entries.map((entry) {
                        int index = entry.key;
                        double qty =
                            (entry.value['qty'] as num).toDouble();

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: qty,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orangeAccent,
                                  Colors.orangeAccent.withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxVentasProducto * 1.1,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
