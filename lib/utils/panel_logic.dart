// Funciones puras extraídas del panel de dueños para facilitar la testabilidad.
//
// Todas las funciones de este archivo son deterministas, sin efectos secundarios
// y sin dependencias de Firebase ni de Flutter. Pueden testearse con dart:test puro.

/// Calcula el total esperado en caja a partir de los componentes de la sesión.
///
/// Fórmula:
///   totalEsperado = saldoInicial + ventasEfectivo − gastosEfectivo − totalCajaFuerte
double calcularTotalEsperado({
  required double saldoInicial,
  required double ventasEfectivo,
  required double gastosEfectivo,
  required double totalCajaFuerte,
}) {
  return saldoInicial + ventasEfectivo - gastosEfectivo - totalCajaFuerte;
}

/// Clasifica un método de pago en una de tres categorías:
///   'efectivo' | 'transferencia' | 'digital'
///
/// Reglas:
///   - Contiene 'efectivo'   → 'efectivo'
///   - Contiene 'transf' o 'banco' → 'transferencia'
///   - Cualquier otro        → 'digital'
String clasificarMetodoPago(String metodo) {
  final m = metodo.toLowerCase();
  if (m.contains('efectivo')) return 'efectivo';
  if (esTransferencia(metodo)) return 'transferencia';
  return 'digital';
}

/// Devuelve true si el método de pago es una transferencia bancaria.
///
/// Un método se considera transferencia si su nombre (en minúsculas) contiene
/// 'transf' o 'banco'.
bool esTransferencia(String metodo) {
  final m = metodo.toLowerCase();
  return m.contains('transf') || m.contains('banco');
}

/// Calcula el total de un carrito de productos.
///
/// Cada ítem debe tener las claves:
///   - 'precio' (num)
///   - 'cantidad' (num)
double calcularCartTotal(List<Map<String, dynamic>> cart) {
  return cart.fold(
    0.0,
    (acc, item) =>
        acc +
        (item['precio'] as num).toDouble() *
            (item['cantidad'] as num).toDouble(),
  );
}

/// Valida que los montos de un pago mixto sumen el total esperado.
///
/// Acepta un margen de error de ±0.50 para cubrir diferencias de punto flotante.
bool validarPagoMixto(Map<String, double> pagoMixto, double total) {
  final efectivo = pagoMixto['efectivo'] ?? 0.0;
  final mp = pagoMixto['mercadopago'] ?? 0.0;
  final transf = pagoMixto['transferencia'] ?? 0.0;
  return (efectivo + mp + transf - total).abs() <= 0.5;
}

/// Construye la lista de pagos en formato estándar para Firestore.
///
/// Si [metodoSeleccionado] es 'Mixto', desglosa los montos individuales.
/// De lo contrario, genera un único pago por el [total] completo.
List<Map<String, dynamic>> construirPagos({
  required String metodoSeleccionado,
  required Map<String, double> pagoMixto,
  required double total,
}) {
  final List<Map<String, dynamic>> pagos = [];

  if (metodoSeleccionado == 'Mixto') {
    final efectivo = pagoMixto['efectivo'] ?? 0.0;
    final mp = pagoMixto['mercadopago'] ?? 0.0;
    final transf = pagoMixto['transferencia'] ?? 0.0;

    if (efectivo > 0) pagos.add({'metodo': 'efectivo', 'monto': efectivo});
    if (mp > 0) pagos.add({'metodo': 'mercadopago', 'monto': mp});
    if (transf > 0) pagos.add({'metodo': 'transferencia', 'monto': transf});
  } else {
    pagos.add({'metodo': metodoSeleccionado.toLowerCase(), 'monto': total});
  }

  return pagos;
}

/// Calcula el índice de chartIndex para un gráfico de ventas por fecha.
///
/// Dado que el gráfico tiene [days] posiciones (0..days-1), hoy corresponde
/// al índice [days - 1] y días anteriores al índice correspondiente.
///
/// Retorna null si la fecha queda fuera del rango (>= days días atrás).
int? calcularChartIndex(DateTime ahora, DateTime fecha, int days) {
  final int diffInDays = ahora
      .difference(DateTime(fecha.year, fecha.month, fecha.day))
      .inDays;
  if (diffInDays >= days) return null;
  return (days - 1) - diffInDays;
}
