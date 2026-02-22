import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:barapp/services/finanzas_service.dart';

class GastosPieChart extends StatelessWidget {
  final String placeId;
  const GastosPieChart({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: FinanzasService(placeId: placeId).getGastosPorCategoria(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "No hay datos para mostrar",
                style: TextStyle(color: Colors.white24),
              ),
            ),
          );
        }

        final datos = snapshot.data!;
        // Colores para las categorías
        final List<Color> colores = [
          Colors.orangeAccent,
          Colors.blueAccent,
          Colors.redAccent,
          Colors.greenAccent,
          Colors.purpleAccent,
          Colors.yellowAccent,
        ];

        return Column(
          children: [
            const Text(
              "DISTRIBUCIÓN DE GASTOS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130, // Antes era 200, bajamos a 130
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 25, // Achicamos el centro
                  sections: _buildSections(datos, colores),
                ),
              ),
            ),
            // Dentro del build de GastosPieChart, al final:
            const SizedBox(height: 10),
            Wrap(
              // <--- CAMBIA Row por Wrap aquí también
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children:
                  datos.keys.map((cat) {
                    int index = datos.keys.toList().indexOf(cat);
                    return _buildLegendItem(
                      cat,
                      colores[index % colores.length],
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> datos,
    List<Color> colores,
  ) {
    int i = 0;
    return datos.entries.map((entry) {
      final color = colores[i % colores.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '\$${entry.value.toInt()}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
