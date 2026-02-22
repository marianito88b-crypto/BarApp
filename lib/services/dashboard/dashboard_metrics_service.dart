import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_filter_utils.dart';

class DashboardMetricsResult {
  final double total;
  final double efectivo;
  final double digital;
  final double envios;
  final double local;
  final double online;

  const DashboardMetricsResult({
    required this.total,
    required this.efectivo,
    required this.digital,
    required this.envios,
    required this.local,
    required this.online,
  });
}

class DashboardMetricsService {
  static final Map<String, DashboardMetricsResult> _cache = {};

  static void clearCache() => _cache.clear();

  // 🔥 HELPER DE SEGURIDAD (Para leer números aunque vengan como String)
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DashboardMetricsResult calculate({
    required List<QueryDocumentSnapshot> docs,
    required String filtro,
  }) {
    if (_cache.containsKey(filtro)) return _cache[filtro]!;

    double totalSum = 0;
    double efectivoSum = 0;
    double digitalSum = 0;
    double enviosSum = 0;
    double localSum = 0;
    double onlineSum = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // 1. Lectura Blindada de Totales
      final double totalDoc = _safeDouble(data['total']);
      final double costoEnvio = _safeDouble(data['totalEnvio']); // 🔥 Clave para que aparezcan los envíos
      final List<dynamic> pagos = data['pagos'] ?? [];

      // 2. Filtro General (Si no pasa el filtro, ignoramos el doc)
      if (!DashboardFilterUtils.matchFiltro(doc: doc, filtro: filtro)) continue;

      // 3. Sumatoria SEGÚN FILTRO ACTIVO
      double montoParaEsteFiltro = 0;

      if (filtro == 'TODOS') {
        montoParaEsteFiltro = totalDoc;
        // Solo sumamos envíos al total global de envíos si estamos viendo TODOS
        enviosSum += costoEnvio; 
      } else {
        // Si hay filtro activo, sumamos QUIRÚRGICAMENTE solo los pagos que coinciden
        bool huboCoincidencia = false;
        
        for (var p in pagos) {
          final String m = (p['metodo'] ?? '').toString().toLowerCase();
          final double montoPago = _safeDouble(p['monto']);
          
          bool match = false;
          if (filtro == 'MERCADOPAGO') {
            match = m.contains('qr') || m.contains('mercado');
          } else if (filtro == 'TRANSFERENCIA') {
            match = m.contains('transf');
          } else if (filtro == 'EFECTIVO') {
            match = m.contains('efectivo');
          } else if (filtro == 'TARJETA') {
            match = m.contains('tarjeta') || m.contains('débito') || m.contains('crédito');
          }

          if (match) {
            montoParaEsteFiltro += montoPago;
            huboCoincidencia = true;
          }
        }
        
        // Fallback para ventas viejas sin array de pagos (asumimos total si el filtro coincide con metodoPrincipal)
        if (!huboCoincidencia && pagos.isEmpty) {
           // Aquí confiamos en que matchFiltro ya validó el metodoPrincipal
           montoParaEsteFiltro = totalDoc;
        }
      }

      totalSum += montoParaEsteFiltro;

      // 4. Desglose CAJA vs BANCO (Para la barra de progreso)
      // 🔥 MEJORA: Leemos el array de pagos real para mayor precisión
      double docEfectivo = 0;
      double docDigital = 0;

      if (pagos.isNotEmpty) {
        for (var p in pagos) {
          final String m = (p['metodo'] ?? '').toString().toLowerCase();
          final double mont = _safeDouble(p['monto']);
          if (m.contains('efectivo')) {
            docEfectivo += mont;
          } else {
            docDigital += mont;
          }
        }
      } else {
        // Fallback data vieja
        docEfectivo = _safeDouble(data['totalEfectivo']);
        docDigital = _safeDouble(data['totalDigital']);
        
        // Si todo es 0, usamos el método principal
        if (docEfectivo == 0 && docDigital == 0 && totalDoc > 0) {
           final String principal = (data['metodoPrincipal'] ?? '').toString().toLowerCase();
           if (principal.contains('efectivo')) {
             docEfectivo = totalDoc;
           } else {
             docDigital = totalDoc;
           }
        }
      }

      efectivoSum += docEfectivo;
      digitalSum += docDigital;

      // 5. Origen (App vs Local)
      if ((data['origen'] ?? 'local') == 'app') {
        onlineSum += totalDoc;
      } else {
        localSum += totalDoc;
      }
    }

    final result = DashboardMetricsResult(
      total: totalSum,
      efectivo: efectivoSum,
      digital: digitalSum,
      envios: enviosSum, // ✅ Ahora sí se va a ver
      local: localSum,
      online: onlineSum,
    );

    _cache[filtro] = result;
    return result;
  }
}