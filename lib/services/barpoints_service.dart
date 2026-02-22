import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar el sistema de BarPoints (Fidelización)
///
/// BarPoints es un sistema de puntos de fidelización donde:
/// - Los usuarios ganan puntos al realizar pedidos (1 punto por cada 1000 ARS)
/// - Los puntos se acreditan cuando el pedido se completa
/// - Cada movimiento se registra en historial_puntos para trazabilidad
class BarPointsService {
  static const double puntosPorMilPesos = 1.0;
  static const int maxBarPoints = 500;
  static final _db = FirebaseFirestore.instance;

  /// Niveles de canje: {puntos: porcentajeDescuento}
  static const Map<int, int> nivelesCanje = {
    100: 5,
    250: 12,
    400: 20,
    500: 30,
  };

  /// Calcula los puntos estimados que ganará el usuario basado en el total del pedido
  static int calcularPuntosEstimados(double total) {
    if (total <= 0) return 0;
    return (total / 1000).floor();
  }

  /// Resuelve la DocumentReference del usuario (users o usuarios)
  static Future<DocumentReference<Map<String, dynamic>>?> _resolveUserRef(
    String userId,
  ) async {
    for (final col in ['usuarios', 'users']) {
      final ref = _db.collection(col).doc(userId);
      if ((await ref.get()).exists) return ref;
    }
    return null;
  }

  /// Registra un movimiento en historial_puntos.
  /// [concepto]: Descripción (ej: "Compra en Bar de Moe", "Bonus 3ra calificación")
  /// [monto]: Positivo = crédito, negativo = débito
  static Future<void> registrarMovimiento({
    required String userId,
    required String concepto,
    required int monto,
    String? orderId,
    String? placeId,
  }) async {
    if (monto == 0) return;
    try {
      final userRef = await _resolveUserRef(userId);
      if (userRef == null) {
        debugPrint('⚠️ [BarPoints] Usuario no encontrado para historial: $userId');
        return;
      }
      await userRef.collection('historial_puntos').add({
        'concepto': concepto,
        'monto': monto,
        'fecha': Timestamp.now(),
        if (orderId != null) 'orderId': orderId,
        if (placeId != null) 'placeId': placeId,
      });
      debugPrint('✅ [BarPoints] Movimiento registrado: $concepto $monto');
    } catch (e) {
      debugPrint('❌ [BarPoints] Error registrando movimiento: $e');
    }
  }

  /// Acredita los puntos al usuario cuando un pedido se completa
  /// y registra el movimiento en historial_puntos
  static Future<bool> acreditarPuntos({
    required String userId,
    required String orderId,
    required String placeId,
    required int puntosEstimados,
  }) async {
    if (puntosEstimados <= 0) {
      debugPrint('⚠️ No hay puntos para acreditar (puntosEstimados: $puntosEstimados)');
      return false;
    }

    try {
      final orderRef = _db
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId);

      final orderDoc = await orderRef.get();
      if (!orderDoc.exists) {
        debugPrint('❌ Pedido no encontrado: $orderId');
        return false;
      }

      final orderData = orderDoc.data();
      if (orderData == null) return false;

      final puntosAcreditados = (orderData['puntosAcreditados'] as bool?) ?? false;
      if (puntosAcreditados) {
        debugPrint('⚠️ Los puntos ya fueron acreditados');
        return false;
      }

      final userRef = await _resolveUserRef(userId);
      if (userRef == null) {
        debugPrint('❌ Usuario no encontrado: $userId');
        return false;
      }

      final userDoc = await userRef.get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final puntosActuales = (userData['barPoints'] as num?)?.toInt() ?? 0;
      // Cap: no acumular más de 500 puntos
      final nuevosPuntos =
          (puntosActuales + puntosEstimados).clamp(0, maxBarPoints);

      // Nombre del lugar para el concepto
      String placeNombre = 'Local';
      try {
        final placeSnap = await _db.collection('places').doc(placeId).get();
        if (placeSnap.exists) {
          placeNombre = placeSnap.data()?['nombre'] as String? ?? 'Local';
        }
      } catch (_) {}

      final concepto = 'Compra en $placeNombre';

      final batch = _db.batch();

      batch.update(userRef, {'barPoints': nuevosPuntos});

      batch.update(orderRef, {
        'puntosAcreditados': true,
        'puntosAcreditadosAt': FieldValue.serverTimestamp(),
      });

      final historialRef = userRef.collection('historial_puntos').doc();
      batch.set(historialRef, {
        'concepto': concepto,
        'monto': puntosEstimados,
        'fecha': Timestamp.now(),
        'orderId': orderId,
        'placeId': placeId,
      });

      await batch.commit();

      debugPrint(
        '✅ Puntos acreditados: +$puntosEstimados al usuario $userId '
        '(Total: $puntosActuales → $nuevosPuntos)',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error acreditando puntos: $e');
      return false;
    }
  }

  /// Canjea puntos por un cupón de descuento.
  /// Resta los puntos, crea el cupón en mis_cupones y registra el movimiento.
  ///
  /// [userId]: ID del usuario
  /// [puntos]: Puntos a canjear (100, 250, 400 o 500)
  /// [descuentoPorcentaje]: Porcentaje del nivel (5, 12, 20, 30)
  ///
  /// Retorna mapa con: success, codigoCupon (si ok), error (si falla)
  static Future<Map<String, dynamic>> canjearPuntos({
    required String userId,
    required int puntos,
    required int descuentoPorcentaje,
  }) async {
    if (!nivelesCanje.containsKey(puntos) ||
        nivelesCanje[puntos] != descuentoPorcentaje) {
      return {'success': false, 'error': 'Nivel de canje inválido'};
    }

    try {
      final userRef = await _resolveUserRef(userId);
      if (userRef == null) {
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      final userDoc = await userRef.get();
      final userData = userDoc.data();
      if (userData == null) {
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      final puntosActuales = (userData['barPoints'] as num?)?.toInt() ?? 0;
      if (puntosActuales < puntos) {
        return {
          'success': false,
          'error': 'No tenés suficientes puntos. Tenés $puntosActuales.',
        };
      }

      final nuevosPuntos = puntosActuales - puntos;

      // Crear cupón (origen BarPoints, válido en locales adheridos)
      final codigoCupon = await _crearCuponBarPoints(
        userRef: userRef,
        puntos: puntos,
        descuentoPorcentaje: descuentoPorcentaje,
      );

      final batch = _db.batch();
      batch.update(userRef, {'barPoints': nuevosPuntos});
      final historialRef = userRef.collection('historial_puntos').doc();
      batch.set(historialRef, {
        'concepto': 'Canje $puntos pts → $descuentoPorcentaje% descuento',
        'monto': -puntos,
        'fecha': Timestamp.now(),
      });

      await batch.commit();

      debugPrint(
        '✅ Canje: $userId usó $puntos pts → cupón $codigoCupon '
        '($puntosActuales → $nuevosPuntos)',
      );
      return {
        'success': true,
        'codigoCupon': codigoCupon,
        'puntosRestantes': nuevosPuntos,
      };
    } catch (e) {
      debugPrint('❌ Error canjeando puntos: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<String> _crearCuponBarPoints({
    required DocumentReference<Map<String, dynamic>> userRef,
    required int puntos,
    required int descuentoPorcentaje,
  }) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final code = List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();

    final vencimiento = DateTime.now().add(const Duration(hours: 24));
    await userRef.collection('mis_cupones').add({
      'codigo': code,
      'placeId': '', // Válido en locales adheridos
      'placeName': 'BarPoints - Locales adheridos',
      'descuentoPorcentaje': descuentoPorcentaje.toDouble(),
      'descripcion': 'Canje BarPoints ($puntos pts) - $descuentoPorcentaje% descuento',
      'creadoEn': FieldValue.serverTimestamp(),
      'usado': false,
      'usadoEn': null,
      'origenBarpoints': true,
      'fechaVencimiento': Timestamp.fromDate(vencimiento),
      'validoHasta': Timestamp.fromDate(vencimiento),
    });
    return code;
  }

  /// Obtiene los BarPoints actuales de un usuario
  static Future<int> obtenerBarPoints(String userId) async {
    try {
      for (final col in ['usuarios', 'users']) {
        final doc = await _db.collection(col).doc(userId).get();
        if (doc.exists) {
          final barPoints = doc.data()?['barPoints'];
          if (barPoints is num) return barPoints.toInt();
          return 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error obteniendo BarPoints: $e');
      return 0;
    }
  }
}
