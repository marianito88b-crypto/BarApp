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
        'fecha': FieldValue.serverTimestamp(), // ✅ Reloj del servidor
        if (orderId != null) 'orderId': orderId,
        if (placeId != null) 'placeId': placeId,
      });
      debugPrint('✅ [BarPoints] Movimiento registrado: $concepto $monto');
    } catch (e) {
      debugPrint('❌ [BarPoints] Error registrando movimiento: $e');
    }
  }

  /// Acredita los puntos al usuario cuando un pedido se completa
  /// y registra el movimiento en historial_puntos.
  /// Usa runTransaction para verificación atómica de saldo y evitar doble acreditación.
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

      final userRef = await _resolveUserRef(userId);
      if (userRef == null) {
        debugPrint('❌ Usuario no encontrado: $userId');
        return false;
      }

      // Nombre del lugar (fuera de transacción, solo lectura)
      String placeNombre = 'Local';
      try {
        final placeSnap = await _db.collection('places').doc(placeId).get();
        if (placeSnap.exists) {
          placeNombre = placeSnap.data()?['nombre'] as String? ?? 'Local';
        }
      } catch (_) {}

      await _db.runTransaction((tx) async {
        // 1. Leer pedido DENTRO de la transacción
        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) {
          throw Exception('Pedido no encontrado');
        }
        final orderData = orderSnap.data();
        if (orderData == null) {
          throw Exception('Pedido no encontrado');
        }

        final puntosAcreditados = (orderData['puntosAcreditados'] as bool?) ?? false;
        if (puntosAcreditados) {
          throw Exception('Los puntos ya fueron acreditados');
        }

        // 2. Leer saldo usuario DENTRO de la transacción
        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          throw Exception('Usuario no encontrado');
        }
        final userData = userSnap.data();
        if (userData == null) {
          throw Exception('Usuario no encontrado');
        }

        final puntosActuales = (userData['barPoints'] as num?)?.toInt() ?? 0;
        final nuevosPuntos =
            (puntosActuales + puntosEstimados).clamp(0, maxBarPoints);
        final concepto = 'Compra en $placeNombre';

        // 3. Todas las escrituras atómicas
        tx.update(userRef, {'barPoints': nuevosPuntos});
        tx.update(orderRef, {
          'puntosAcreditados': true,
          'puntosAcreditadosAt': FieldValue.serverTimestamp(),
        });
        tx.set(userRef.collection('historial_puntos').doc(), {
          'concepto': concepto,
          'monto': puntosEstimados,
          'fecha': FieldValue.serverTimestamp(),
          'orderId': orderId,
          'placeId': placeId,
        });
      });

      debugPrint('✅ Puntos acreditados: +$puntosEstimados al usuario $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error acreditando puntos: $e');
      return false;
    }
  }

  /// Canjea puntos por un cupón de descuento.
  /// Resta los puntos, crea el cupón en mis_cupones y registra el movimiento.
  /// Usa runTransaction para prevenir doble gasto (dos canjes simultáneos).
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

      String codigoCupon = '';
      int capturedNuevosPuntos = 0; // Capturado dentro de la tx para evitar re-lectura

      await _db.runTransaction((tx) async {
        // 1. Leer saldo actual DENTRO de la transacción (verificación atómica)
        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          throw Exception('Usuario no encontrado');
        }
        final userData = userSnap.data();
        if (userData == null) {
          throw Exception('Usuario no encontrado');
        }

        final puntosActuales = (userData['barPoints'] as num?)?.toInt() ?? 0;
        if (puntosActuales < puntos) {
          throw Exception('No tenés suficientes puntos. Tenés $puntosActuales.');
        }

        final nuevosPuntos = puntosActuales - puntos;
        capturedNuevosPuntos = nuevosPuntos; // Guardar para retornar sin extra-read

        // 2. Generar código y preparar datos del cupón
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        final r = Random.secure();
        codigoCupon = List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
        final vencimiento = DateTime.now().add(const Duration(hours: 24));

        // 3. Todas las escrituras en la misma transacción
        tx.update(userRef, {'barPoints': nuevosPuntos});

        final historialRef = userRef.collection('historial_puntos').doc();
        tx.set(historialRef, {
          'concepto': 'Canje $puntos pts → $descuentoPorcentaje% descuento',
          'monto': -puntos,
          'fecha': FieldValue.serverTimestamp(), // ✅ Reloj del servidor (consistente con acreditarPuntos)
        });

        final cuponRef = userRef.collection('mis_cupones').doc();
        tx.set(cuponRef, {
          'codigo': codigoCupon,
          'placeId': '',
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
      });

      debugPrint('✅ Canje: $userId usó $puntos pts → cupón $codigoCupon');
      return {
        'success': true,
        'codigoCupon': codigoCupon,
        'puntosRestantes': capturedNuevosPuntos, // ✅ Valor exacto, sin lectura extra
      };
    } on Exception catch (e) {
      debugPrint('❌ Error canjeando puntos: $e');
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    } catch (e) {
      debugPrint('❌ Error canjeando puntos: $e');
      return {'success': false, 'error': e.toString()};
    }
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
