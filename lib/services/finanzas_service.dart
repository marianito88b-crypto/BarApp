import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FinanzasService {
  final String placeId;
  FinanzasService({required this.placeId});

  DateTime get _inicioMes => DateTime(DateTime.now().year, DateTime.now().month, 1);

  // 1. GASTOS MENSUALES (CORREGIDO ✅)
  // Solo suma si estado == 'pagado'
  Stream<double> getGastosMensuales() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('gastos')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(_inicioMes))
        .snapshots()
        .map((snap) {
          return snap.docs.fold(0.0, (acc, doc) {
            final data = doc.data();
            // 🔥 FILTRO CLAVE: Si es deuda pendiente, NO RESTA de la caja hoy.
            if (data['estado'] == 'pendiente') return acc;
            
            return acc + (data['monto'] ?? 0.0);
          });
        });
  }

  // 2. INGRESOS MENSUALES (Sin cambios, estaba bien)
  Stream<double> getIngresosMensuales() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(_inicioMes))
        .snapshots()
        .map((snap) {
          return snap.docs.fold(0.0, (acc, doc) {
            return acc + (doc['total']?.toDouble() ?? 0.0);
          });
        });
  }

  // 3. GASTOS POR CATEGORÍA (CORREGIDO ✅)
  // Solo categorizamos lo que realmente se pagó para no ensuciar el gráfico
  Stream<Map<String, double>> getGastosPorCategoria() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('gastos')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(_inicioMes))
        .snapshots()
        .map((snap) {
          Map<String, double> totales = {};
          for (var doc in snap.docs) {
            final data = doc.data();
            // 🔥 FILTRO CLAVE
            if (data['estado'] == 'pendiente') continue;

            String cat = data['categoria'] ?? 'Varios';
            double monto = (data['monto'] ?? 0.0).toDouble();
            totales[cat] = (totales[cat] ?? 0.0) + monto;
          }
          return totales;
        });
  }

  // 4. COMPARATIVA SEMANAL (CORREGIDO ✅)
  // Escucha AMBAS colecciones para no servir datos stale cuando solo cambian gastos
  Stream<List<Map<String, dynamic>>> getComparativaSemanal() {
    DateTime haceUnaSemana = DateTime.now().subtract(const Duration(days: 6));

    final ventasQuery = FirebaseFirestore.instance
        .collection('places').doc(placeId).collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(haceUnaSemana));

    final gastosQuery = FirebaseFirestore.instance
        .collection('places').doc(placeId).collection('gastos')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(haceUnaSemana));

    QuerySnapshot? lastVentas;
    QuerySnapshot? lastGastos;
    StreamSubscription? vSub;
    StreamSubscription? gSub;

    late final StreamController<List<Map<String, dynamic>>> controller;

    void recompute() {
      if (lastVentas == null || lastGastos == null) return;

      List<Map<String, dynamic>> dias = [];
      for (int i = 0; i < 7; i++) {
        DateTime fechaDia = haceUnaSemana.add(Duration(days: i));
        double totalVenta = 0;
        double totalGasto = 0;

        for (var doc in lastVentas!.docs) {
          DateTime f = (doc['fecha'] as Timestamp).toDate();
          if (f.year == fechaDia.year && f.month == fechaDia.month && f.day == fechaDia.day) {
            totalVenta += (doc['total'] ?? 0).toDouble();
          }
        }

        for (var doc in lastGastos!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          // 🔥 FILTRO CLAVE: Solo sumamos al gráfico si está PAGADO
          if (data['estado'] == 'pendiente') continue;

          DateTime f = (data['fecha'] as Timestamp).toDate();
          if (f.year == fechaDia.year && f.month == fechaDia.month && f.day == fechaDia.day) {
            totalGasto += (data['monto'] ?? 0).toDouble();
          }
        }

        dias.add({
          'dia': _getNombreDia(fechaDia.weekday),
          'ventas': totalVenta,
          'gastos': totalGasto,
        });
      }
      controller.add(dias);
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        vSub = ventasQuery.snapshots().listen((s) {
          lastVentas = s;
          recompute();
        });
        gSub = gastosQuery.snapshots().listen((s) {
          lastGastos = s;
          recompute();
        });
      },
      onCancel: () {
        vSub?.cancel();
        gSub?.cancel();
      },
    );

    return controller.stream;
  }

  String _getNombreDia(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mie';
      case 4: return 'Jue';
      case 5: return 'Vie';
      case 6: return 'Sab';
      case 7: return 'Dom';
      default: return '';
    }
  }
}