import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra un gráfico de líneas con la evolución de ventas
class SalesLineChart extends StatelessWidget {
  final List<FlSpot> chartSpots;
  final double maxY;
  final bool isWeekly;

  const SalesLineChart({
    super.key,
    required this.chartSpots,
    required this.maxY,
    required this.isWeekly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY > 0 ? maxY / 4 : 1,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 22,
                getTitlesWidget: (val, meta) {
                  // Mostramos dias intercalados si son 30
                  if (!isWeekly && val % 5 != 0) {
                    return const SizedBox.shrink();
                  }

                  // Calculamos fecha para el label
                  final date = DateTime.now().subtract(
                    Duration(days: (isWeekly ? 7 : 30) - 1 - val.toInt()),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd').format(date),
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (isWeekly ? 6 : 29).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: chartSpots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.orangeAccent,
                    strokeWidth: 1,
                    strokeColor: Colors.black,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent.withValues(alpha: 0.3),
                    Colors.orangeAccent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
