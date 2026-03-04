import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Mixin que proporciona la lógica de datos para las métricas avanzadas.
/// 
/// Este mixin maneja:
/// - Carga de datos desde Firestore
/// - Procesamiento de ventas, sesiones y productos
/// - Estado de carga y variables de métricas
mixin MetricsLogicMixin<T extends StatefulWidget> on State<T> {
  // Variables de estado de carga
  bool isLoading = true;

  // Variables de estado de métricas
  double totalIngresos = 0;
  double ingresosPeriodoAnterior = 0;
  int totalCierres = 0;

  double totalEfectivo = 0;
  double totalDigital = 0;
  double totalTransferencia = 0;

  List<FlSpot> chartSpots = [];
  double maxY = 0;

  List<Map<String, dynamic>> listaSesiones = [];
  List<Map<String, dynamic>> topProductos = [];
  double maxVentasProducto = 0;

  /// Determina si un método de pago es transferencia bancaria
  bool esTransferencia(String metodo) {
    return metodo.contains('transf') || metodo.contains('banco');
  }

  /// Obtiene el placeId del widget.
  /// 
  /// Debe ser implementado por la clase que usa el mixin
  /// para proporcionar el ID del lugar.
  String get placeId;

  /// Obtiene si el periodo es semanal (true) o mensual (false).
  /// 
  /// Debe ser implementado por la clase que usa el mixin.
  bool get isWeekly;

  /// Carga los datos de métricas desde Firestore.
  /// 
  /// Maneja correctamente el estado de carga y actualiza
  /// todas las variables de estado relacionadas con métricas.
  /// 
  /// MEJORA DE RENDIMIENTO:
  /// - Verifica `mounted` antes de cada `setState`
  /// - Maneja errores correctamente sin dejar el estado en loading
  /// - Usa agregaciones de Firestore para optimizar consultas
  Future<void> fetchData() async {
    // Verificamos que el widget esté montado antes de cambiar el estado
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final int days = isWeekly ? 7 : 30;

      // Definimos los rangos de tiempo
      final startCurrent = now.subtract(Duration(days: days));
      final startPrevious = startCurrent.subtract(Duration(days: days));

      // 1. VENTAS DEL PERIODO ACTUAL (Limitamos para no fundir el presupuesto)
      final queryVentas = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startCurrent))
          .orderBy('fecha', descending: true)
          .limit(days * 100) // Un promedio sano de ventas por día
          .get();

      // 2. SESIONES DE CAJA
      final querySesiones = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('caja_sesiones')
          .where('fecha_apertura', isGreaterThanOrEqualTo: Timestamp.fromDate(startCurrent))
          .orderBy('fecha_apertura', descending: true)
          .get();

      // 3. COMPARATIVA PERIODO ANTERIOR (MODO SENIOR: Solo sumamos en servidor)
      // Esto ahorra miles de lecturas porque no descarga los documentos
      final aggregateQuery = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startPrevious))
          .where('fecha', isLessThan: Timestamp.fromDate(startCurrent))
          .aggregate(sum('total'))
          .get();

      double prevSum = aggregateQuery.getSum('total')?.toDouble() ?? 0;

      // --- PROCESAMIENTO DE DATOS ---
      double currentSum = 0;
      double sumEfectivo = 0;
      double sumDigital = 0;
      double sumTransferencia = 0;

      // Usamos un Map con el índice del día (0 a N) para que sea único
      Map<int, double> salesByChartIndex = {};
      Map<String, int> productCounter = {};

      for (var doc in queryVentas.docs) {
        final data = doc.data();
        final double total = (data['total'] as num?)?.toDouble() ?? 0;
        currentSum += total;

        Timestamp? ts = data['fecha'];
        if (ts == null) continue;
        final date = ts.toDate();

        // 🔥 CORRECCIÓN CRÍTICA: Índice único para el gráfico (Días de diferencia)
        // Esto evita que se pisen los días si cruzamos un mes (ej: 24 de enero y 24 de diciembre)
        final int diffInDays = now.difference(date).inDays;
        if (diffInDays < days) {
          final int chartIndex = (days - 1) - diffInDays;
          salesByChartIndex[chartIndex] = (salesByChartIndex[chartIndex] ?? 0) + total;
        }

        // 🔥 CLASIFICACIÓN UNIFICADA
        final List pagos = data['pagos'] ?? [];
        if (pagos.isNotEmpty) {
          for (final p in pagos) {
            final String m = (p['metodo'] ?? '').toString().toLowerCase();
            final double montoPago = (p['monto'] as num?)?.toDouble() ?? 0.0;

            if (esTransferencia(m)) {
              sumTransferencia += montoPago;
            } else if (m.contains('efectivo')) {
              sumEfectivo += montoPago;
            } else {
              sumDigital += montoPago;
            }
          }
        } else {
          final String m = (data['metodoPrincipal'] ?? data['metodoPago'] ?? 'efectivo')
              .toString()
              .toLowerCase();
          if (esTransferencia(m)) {
            sumTransferencia += total;
          } else if (m.contains('efectivo')) {
            sumEfectivo += total;
          } else {
            sumDigital += total;
          }
        }

        // Top Productos
        if (data['items'] != null) {
          for (var item in data['items']) {
            final nombre = item['nombre'] ?? 'S/N';
            final qty = (item['cantidad'] as num?)?.toInt() ?? 1;
            productCounter[nombre] = (productCounter[nombre] ?? 0) + qty;
          }
        }
      }

      // 4. GENERACIÓN DE SPOTS PARA EL GRÁFICO (Sin huecos)
      List<FlSpot> spots = [];
      double maxVal = 0;
      for (int i = 0; i < days; i++) {
        final double val = salesByChartIndex[i] ?? 0;
        if (val > maxVal) maxVal = val;
        spots.add(FlSpot(i.toDouble(), val));
      }

      // 5. TOP PRODUCTOS
      final sortedProds = productCounter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final int limit = isWeekly ? 5 : 10;
      final topList = sortedProds
          .take(limit)
          .map((e) => {'nombre': e.key, 'qty': e.value})
          .toList();

      double maxProdQty = topList.isNotEmpty ? (topList.first['qty'] as num).toDouble() : 0;

      // Sesiones
      List<Map<String, dynamic>> tempSesiones = querySesiones.docs.map((d) {
        final map = d.data();
        map['id'] = d.id;
        return map;
      }).toList();

      // MEJORA DE RENDIMIENTO: Verificamos mounted antes de cada setState
      if (mounted) {
        setState(() {
          totalIngresos = currentSum;
          ingresosPeriodoAnterior = prevSum;
          totalCierres = tempSesiones.length;
          chartSpots = spots;
          maxY = maxVal == 0 ? 1000 : maxVal * 1.2;
          totalEfectivo = sumEfectivo;
          totalTransferencia = sumTransferencia;
          totalDigital = sumDigital;
          listaSesiones = tempSesiones;
          topProductos = topList;
          maxVentasProducto = maxProdQty;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error crítico en Advanced Metrics: $e");
      // MEJORA DE RENDIMIENTO: Aseguramos que siempre se actualice el estado de carga
      // incluso en caso de error, pero solo si el widget sigue montado
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
