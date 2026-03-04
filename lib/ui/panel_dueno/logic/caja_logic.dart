import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/services/caja_service.dart';

/// Mixin que contiene la lógica de negocio para la gestión de caja
/// 
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
mixin CajaLogicMixin {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Servicio de caja (se inicializa cuando se necesita)
  CajaService? _cajaService;

  /// Obtiene o crea la instancia del servicio de caja
  CajaService get cajaService {
    _cajaService ??= CajaService(placeId);
    return _cajaService!;
  }

  /// Abre una nueva sesión de caja
  /// 
  /// Parámetros:
  /// - [montoInicial]: El monto inicial de la caja
  /// - [responsableEmail]: Email del responsable que abre la caja
  Future<void> abrirCaja(double montoInicial, String responsableEmail) async {
    await cajaService.abrirCaja(montoInicial, responsableEmail);
  }

  /// Cierra una sesión de caja
  /// 
  /// Parámetros:
  /// - [sesionId]: ID de la sesión a cerrar
  /// - [montoReal]: Monto real contado físicamente
  /// - [montoEsperado]: Monto esperado según el sistema
  Future<void> cerrarCaja(
    String sesionId,
    double montoReal,
    double montoEsperado,
  ) async {
    await cajaService.cerrarCaja(sesionId, montoReal, montoEsperado);
  }

  /// Procesa y calcula los totales de ventas desde una fecha de apertura
  /// 
  /// Retorna un mapa con:
  /// - `ventasTotal`: Total de todas las ventas
  /// - `ventasEfectivo`: Total de ventas en efectivo
  /// - `ventasDigital`: Total de ventas digitales
  /// - `gastosEfectivo`: Total de gastos pagados en efectivo
  /// - `totalEsperadoEnCaja`: Saldo esperado en caja (inicial + efectivo - gastos efectivo)
  Future<Map<String, double>> procesarTotalesCaja(
    Timestamp fechaApertura,
    double saldoInicial,
  ) async {
    // Obtener ventas desde la fecha de apertura
    final ventasSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: fechaApertura)
        .get();

    // 🔥 CRÍTICO: Obtener SOLO gastos pagados en efectivo desde la fecha de apertura del turno
    // Esto es vital para un arqueo exacto de la caja
    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('gastos')
        .where('fecha', isGreaterThanOrEqualTo: fechaApertura)
        .where('estado', isEqualTo: 'pagado')
        .get();

    double ventasTotal = 0;
    double ventasEfectivo = 0;
    double ventasDigital = 0;
    double gastosEfectivo = 0;
    double totalCajaFuerte = 0;

    // Procesar Ventas desde la apertura del turno
    for (var doc in ventasSnapshot.docs) {
      final v = doc.data();
      final double totalDoc = (v['total'] as num?)?.toDouble() ?? 0.0;

      ventasTotal += totalDoc;

      // Intentamos leer el array de pagos
      final pagos = v['pagos'] as List<dynamic>? ?? [];

      if (pagos.isNotEmpty) {
        // Si tiene detalle de pagos
        for (var p in pagos) {
          final String metodo = (p['metodo'] ?? '').toString().toLowerCase();
          final double monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
          if (metodo == 'efectivo') {
            ventasEfectivo += monto;
          } else {
            ventasDigital += monto;
          }
        }
      } else {
        // Fallback: Si no tiene array, miramos el método principal
        final String metodoRoot =
            (v['metodoPrincipal'] ?? '').toString().toLowerCase();
        if (metodoRoot == 'efectivo') {
          ventasEfectivo += totalDoc;
        } else {
          ventasDigital += totalDoc;
        }
      }
    }

    // 🔥 CRÍTICO: Procesar SOLO gastos pagados en efectivo desde la apertura
    // Los gastos pendientes (deuda) NO se descuentan de la caja hasta que se paguen
    for (var doc in gastosSnapshot.docs) {
      final g = doc.data();
      // Solo contamos gastos pagados en efectivo (no digitales ni pendientes)
      final String metodo =
          (g['metodoPago'] ?? 'efectivo').toString().toLowerCase();
      if (metodo == 'efectivo') {
        gastosEfectivo += (g['monto'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // 🔥 CRÍTICO: Descontar retiros a caja fuerte
    // Los retiros a caja fuerte sacan físicamente dinero del cajón, por lo tanto
    // deben reducir el saldo esperado aunque no sean un "gasto" contable.
    final cajaFuerteSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('movimientos_caja_fuerte')
        .where('fecha', isGreaterThanOrEqualTo: fechaApertura)
        .get();

    for (var doc in cajaFuerteSnapshot.docs) {
      final cf = doc.data();
      totalCajaFuerte += (cf['monto'] as num?)?.toDouble() ?? 0.0;
    }

    // Calcular saldo esperado
    // IMPORTANTE: El monto inicial NO se suma a lo vendido, solo se muestra separado
    // El total esperado es: monto inicial + ventas efectivo - gastos efectivo - retiros a caja fuerte
    double totalEsperadoEnCaja = saldoInicial + ventasEfectivo - gastosEfectivo - totalCajaFuerte;

    return {
      'ventasTotal': ventasTotal,
      'ventasEfectivo': ventasEfectivo,
      'ventasDigital': ventasDigital,
      'gastosEfectivo': gastosEfectivo,
      'totalCajaFuerte': totalCajaFuerte,
      'totalEsperadoEnCaja': totalEsperadoEnCaja,
      'saldoInicial': saldoInicial, // Incluido explícitamente para referencia
    };
  }

  /// Obtiene el stream de la sesión de caja abierta
  Stream<QuerySnapshot> getSesionAbiertaStream() {
    return cajaService.getSesionAbiertaStream();
  }
}
