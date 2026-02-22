import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:barapp/services/barpoints_service.dart';

/// Sistema de calificación mutua — dos rutas estrictamente separadas:
///
/// ╔══════════════════════════════════════════════════════════════════╗
/// ║  RUTA A — Cliente califica al Bar                               ║
/// ║  Escribe: places/{placeId}/ratings_recibidas/{orderId}          ║
/// ║  Lee:     RatingsHistoryCard (dashboard del dueño)              ║
/// ╠══════════════════════════════════════════════════════════════════╣
/// ║  RUTA B — Bar califica al Cliente                               ║
/// ║  Escribe: {col}/{userId}/reputacion_recibida/{orderId}          ║
/// ║  Lee:     ClientRatingsModal (perfil del cliente)               ║
/// ╚══════════════════════════════════════════════════════════════════╝
///
/// REGLA DE ORO: Nunca usar FieldValue.serverTimestamp() dentro de un
/// Map anidado en un Array — Firestore Web lo rechaza con TypeError.
/// Siempre usar Timestamp.now() para timestamps en estructuras anidadas.
class RatingService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────
  // HELPER: Resuelve la DocumentReference del usuario.
  // Busca primero en 'usuarios' (colección principal), luego en 'users'.
  // ───────────────────────────────────────────────────────────────────
  static Future<DocumentReference<Map<String, dynamic>>?> _resolveUserRef(
    String userId,
  ) async {
    for (final col in ['usuarios', 'users']) {
      final ref = _db.collection(col).doc(userId);
      if ((await ref.get()).exists) {
        debugPrint('✅ [RatingService] Usuario en "$col": $userId');
        return ref;
      }
    }
    debugPrint('❌ [RatingService] Usuario no encontrado: $userId');
    return null;
  }

  // ───────────────────────────────────────────────────────────────────
  // HELPER: Verifica si el userId es owner del bar.
  // Bloquea calificaciones de un dueño a su propio negocio.
  // ───────────────────────────────────────────────────────────────────
  static Future<bool> _esOwnerDelBar(String userId, String placeId) async {
    try {
      final snap = await _db.collection('places').doc(placeId).get();
      if (!snap.exists) return false;
      final d = snap.data()!;
      return userId == (d['ownerId'] as String?) ||
          userId == (d['userId'] as String?);
    } catch (_) {
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  RUTA A: Cliente → Bar                                          ║
  // ╚══════════════════════════════════════════════════════════════════╝
  //
  // Campos guardados:
  //   clienteId     → uid del cliente autenticado
  //   clienteNombre → nombre del cliente (del pedido)
  //   estrellas     → int 1-5
  //   etiquetas     → List<String> con las opciones seleccionadas
  //   comentarios   → String libre opcional
  //   timestamp     → Timestamp.now()
  //
  // Guarda también rating_entrega en el pedido para compatibilidad.
  static Future<bool> calificarEntrega({
    required String orderId,
    required String placeId,
    required int estrellas,
    required List<String> etiquetas,
    String comentarios = '',
  }) async {
    try {
      if (estrellas < 1 || estrellas > 5) {
        debugPrint('❌ [calificarEntrega] Estrellas inválidas: $estrellas');
        return false;
      }

      // 1. Obtener datos del pedido
      final orderRef = _db
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        debugPrint('❌ [calificarEntrega] Pedido no encontrado: $orderId');
        return false;
      }

      final orderData = orderSnap.data()!;
      final clienteNombre =
          orderData['clienteNombre'] as String? ?? 'Cliente';

      // 2. ClienteId desde Auth (quién está calificando ahora mismo)
      final clienteId =
          FirebaseAuth.instance.currentUser?.uid ?? orderData['userId'] as String? ?? '';

      // 3. Guardia: el dueño no puede calificar su propio bar
      if (clienteId.isNotEmpty && await _esOwnerDelBar(clienteId, placeId)) {
        debugPrint('⚠️ [calificarEntrega] Dueño calificando su propio bar. Bloqueado.');
        return false;
      }

      final now = Timestamp.now();

      // 4. ── RUTA A: subcolección ratings_recibidas del bar ──────────
      await _db
          .collection('places')
          .doc(placeId)
          .collection('ratings_recibidas')
          .doc(orderId)
          .set({
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'estrellas': estrellas,
        'etiquetas': etiquetas,
        'comentarios': comentarios.trim(),
        'timestamp': now,
        'orderId': orderId,
      });

      // 5. Compat: actualizar campo en el pedido
      await orderRef.update({
        'rating_entrega': {
          'estrellas': estrellas,
          'etiquetas': etiquetas,
          'comentarios': comentarios.trim(),
          'timestamp': now,
        },
      });

      debugPrint('✅ [calificarEntrega] Guardado en ratings_recibidas/$orderId');
      return true;
    } catch (e, st) {
      debugPrint('❌ [calificarEntrega] $e\n$st');
      return false;
    }
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  RUTA B: Bar → Cliente                                          ║
  // ╚══════════════════════════════════════════════════════════════════╝
  //
  // Campos guardados:
  //   placeId      → ID del bar
  //   placeNombre  → nombre del bar (resuelto internamente)
  //   estrellas    → int 1-5
  //   etiquetas    → List<String> con las opciones seleccionadas
  //   comentarios  → String libre opcional
  //   timestamp    → Timestamp.now()
  //
  // Guarda en {col}/{userId}/reputacion_recibida/{orderId}
  // Actualiza reputacion_cliente (promedio) en el perfil del usuario.
  // Incrementa total_ratings y otorga bonus de 10 BarPoints c/3 ratings.
  static Future<Map<String, dynamic>> calificarCliente({
    required String userId,
    required String orderId,
    required String placeId,
    required int estrellas,
    required List<String> etiquetas,
    String comentarios = '',
  }) async {
    try {
      // 1. Validaciones básicas
      if (userId.isEmpty || orderId.isEmpty || placeId.isEmpty) {
        return _err('Parámetros inválidos');
      }
      if (estrellas < 1 || estrellas > 5) {
        return _err('Estrellas inválidas (1-5)');
      }

      // 2. Verificar pedido
      final orderRef = _db
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        return _err('Pedido no encontrado');
      }

      final orderData = orderSnap.data()!;
      final orderUserId = orderData['userId'] as String?;
      if (orderUserId == null || orderUserId.isEmpty) {
        return _err('Pedido sin usuario válido');
      }

      // 3. Guardia: no calificar al dueño del mismo bar
      if (await _esOwnerDelBar(orderUserId, placeId)) {
        debugPrint('⚠️ [calificarCliente] Intento de calificar al dueño. Bloqueado.');
        return _err('No se puede calificar al dueño del bar');
      }

      // 4. Obtener nombre del bar
      String placeNombre = 'Bar';
      try {
        final placeSnap = await _db.collection('places').doc(placeId).get();
        if (placeSnap.exists) {
          placeNombre =
              placeSnap.data()?['nombre'] as String? ?? 'Bar';
        }
      } catch (_) {}

      // 5. Resolver la referencia al documento del usuario
      final userRef = await _resolveUserRef(userId);

      final now = Timestamp.now();

      // 6. Compat: actualizar campo rating_cliente en el pedido
      await orderRef.update({
        'rating_cliente': {
          'estrellas': estrellas,
          'etiquetas': etiquetas,
          'comentarios': comentarios.trim(),
          'timestamp': now,
        },
      });

      if (userRef == null) {
        debugPrint(
          '⚠️ [calificarCliente] Usuario no encontrado. Rating guardado solo en pedido.',
        );
        return {
          'success': true,
          'bonusOtorgado': false,
          'totalRatings': 0,
          'warning': 'Calificación guardada en pedido pero usuario no encontrado',
        };
      }

      // 7. ── RUTA B: subcolección reputacion_recibida del usuario ────
      //    orderId como ID del doc → cada pedido tiene su propia reseña
      await userRef.collection('reputacion_recibida').doc(orderId).set({
        'placeId': placeId,
        'placeNombre': placeNombre,
        'orderId': orderId,
        'estrellas': estrellas,
        'etiquetas': etiquetas,
        'comentarios': comentarios.trim(),
        'timestamp': now,
      });

      debugPrint('✅ [calificarCliente] reputacion_recibida/$orderId guardado');

      // 8. Recalcular promedio leyendo TODA la subcolección
      final allSnap = await userRef.collection('reputacion_recibida').get();
      double suma = 0;
      int totalBares = 0;
      for (final doc in allSnap.docs) {
        suma += (doc.data()['estrellas'] as num?)?.toDouble() ?? 0;
        totalBares++;
      }
      final promedio = totalBares > 0 ? suma / totalBares : 0.0;

      // 9. Leer datos del usuario para actualizar promedio + bonus
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};
      final globalTotal =
          ((userData['total_ratings'] as num?)?.toInt() ?? 0) + 1;
      final puntosActuales = (userData['barPoints'] as num?)?.toInt() ?? 0;

      bool bonusOtorgado = false;
      int nuevosPuntos = puntosActuales;
      if (globalTotal % 3 == 0) {
        nuevosPuntos = puntosActuales + 10;
        bonusOtorgado = true;
        debugPrint(
          '🎁 Bonus #$globalTotal: +10 BarPoints → $userId '
          '($puntosActuales → $nuevosPuntos)',
        );
      }

      // 10. Actualizar perfil del usuario
      await userRef.update({
        'reputacion_cliente': {
          'promedioEstrellas': promedio.toDouble(),
          'totalCalificaciones': totalBares,
          'ultimaActualizacion': now,
        },
        'total_ratings': globalTotal,
        'barPoints': nuevosPuntos,
      });

      // 11. Registrar bonus en historial de BarPoints (si aplica)
      if (bonusOtorgado) {
        await BarPointsService.registrarMovimiento(
          userId: userId,
          concepto: 'Bonus 3ra calificación',
          monto: 10,
        );
      }

      debugPrint(
        '✅ [calificarCliente] $estrellas⭐ → $userId '
        '(promedio: ${promedio.toStringAsFixed(1)}, total bares: $totalBares)',
      );

      return {
        'success': true,
        'bonusOtorgado': bonusOtorgado,
        'totalRatings': globalTotal,
      };
    } catch (e, st) {
      debugPrint('❌ [calificarCliente] $e\n$st');
      return _err(e.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────────
  static Map<String, dynamic> _err(String msg) => {
        'success': false,
        'bonusOtorgado': false,
        'totalRatings': 0,
        'error': msg,
      };
}
