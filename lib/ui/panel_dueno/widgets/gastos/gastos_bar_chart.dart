import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de barras comparativo semanal de ventas vs gastos
class GastosBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> datos;

  const GastosBarChart({
    super.key,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.2,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black.withValues(alpha: 0.8),
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "\$${rod.toY.toInt()}",
                  TextStyle(color: rod.color, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      datos[value.toInt()]['dia'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    _formatMontoEje(value),
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  String _formatMontoEje(double value) {
    if (value >= 1000) {
      return "\$${(value / 1000).toStringAsFixed(1)}k";
    }
    return "\$${value.toInt()}";
  }

  double _getMaxY() {
    double max = 0;
    for (var d in datos) {
      if (d['ventas'] > max) max = d['ventas'];
      if (d['gastos'] > max) max = d['gastos'];
    }
    return max == 0 ? 100 : max * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(datos.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: datos[i]['ventas'],
            gradient: const LinearGradient(
              colors: [Colors.greenAccent, Colors.tealAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: datos[i]['gastos'],
            gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.orangeAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
