import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardFilterUtils {
  static bool matchFiltro({
    required QueryDocumentSnapshot doc,
    required String filtro,
  }) {
    if (filtro == 'TODOS') return true;

    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> pagos = data['pagos'] ?? [];
    
    // Campo raíz (respaldo)
    final String metodoRaiz = (data['metodoPrincipal'] ?? data['metodoPago'] ?? '').toString().toLowerCase();

    // 1. Buscamos en el array de pagos detallados (La fuente de la verdad)
    if (pagos.isNotEmpty) {
      return pagos.any((p) {
        final String m = (p['metodo'] ?? '').toString().toLowerCase();
        return _checkMatch(m, filtro);
      });
    }

    // 2. Si no hay array (ventas viejas/web), buscamos en el campo raíz
    return _checkMatch(metodoRaiz, filtro);
  }

  // Lógica centralizada de comparación
  static bool _checkMatch(String metodoEnBase, String filtroSeleccionado) {
    if (metodoEnBase.isEmpty) return false;

    switch (filtroSeleccionado.toUpperCase()) {
      case 'MERCADOPAGO':
        // Abarca QR, Mercado, MP, MercadoPago
        return metodoEnBase.contains('qr') || metodoEnBase.contains('mercado') || metodoEnBase.contains('mp');
      
      case 'TRANSFERENCIA':
        // Abarca Transf, Transferencia, CBU
        return metodoEnBase.contains('transf') || metodoEnBase.contains('cbu');
      
      case 'EFECTIVO':
        return metodoEnBase.contains('efectivo') || metodoEnBase.contains('cash');

      case 'TARJETA':
        return metodoEnBase.contains('tarjeta') || metodoEnBase.contains('posnet') || metodoEnBase.contains('debit') || metodoEnBase.contains('credit');

      default:
        // Por si usas nombres de filtros idénticos a la base (ej: 'BITCOIN')
        return metodoEnBase.contains(filtroSeleccionado.toLowerCase());
    }
  }
}