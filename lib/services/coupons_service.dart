import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Opciones de validez para cupones de premio (panel dueño)
enum ValidezCupon {
  horas24,
  dias3,
  dias7,
}

/// Servicio para gestionar cupones de descuento para clientes
class CouponsService {
  static const _uuid = Uuid();

  /// Normaliza el código para validación: trim, quita espacios, mayúsculas.
  /// Compatible con BarPoints (8 chars) y cupones globales (ej: BIENVENIDA).
  static String normalizarCodigo(String input) {
    if (input.isEmpty) return '';
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
  }

  /// Valida formato mínimo: 3-50 caracteres alfanuméricos (BarPoints=8, globales variables)
  static bool esFormatoCodigoValido(String codigo) {
    if (codigo.isEmpty || codigo.length < 3 || codigo.length > 50) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(codigo);
  }

  /// Duración de validez del cupón (para premios del panel dueño)
  static Duration validezToDuration(ValidezCupon validez) {
    switch (validez) {
      case ValidezCupon.horas24:
        return const Duration(hours: 24);
      case ValidezCupon.dias3:
        return const Duration(days: 3);
      case ValidezCupon.dias7:
        return const Duration(days: 7);
    }
  }

  /// Crea un cupón de descuento para un cliente específico
  /// 
  /// Guarda el cupón en users/{userId}/mis_cupones
  /// 
  /// [userId]: ID del cliente que recibirá el cupón
  /// [placeId]: ID del lugar que otorga el cupón
  /// [placeName]: Nombre del lugar
  /// [codigo]: Código del cupón (si es null, se genera automáticamente)
  /// [descuentoPorcentaje]: Porcentaje de descuento (ej: 10 para 10%)
  /// [descripcion]: Descripción opcional del cupón
  /// [validez]: Validez del cupón (24h, 3 días, 7 días). Por defecto 7 días.
  /// 
  /// Retorna el código del cupón creado
  static Future<String> crearCupon({
    required String userId,
    required String placeId,
    required String placeName,
    String? codigo,
    double? descuentoPorcentaje,
    String? descripcion,
    ValidezCupon validez = ValidezCupon.dias7,
  }) async {
    try {
      // Generar código si no se proporciona
      final codigoFinal = codigo ?? _generarCodigoCupon();

      // Buscar usuario en ambas colecciones
      var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
        userDoc = await userRef.get();
      }

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      // Crear documento del cupón en la subcolección mis_cupones
      final cuponRef = userRef.collection('mis_cupones').doc();

      final validoHastaDate =
          DateTime.now().add(validezToDuration(validez));

      await cuponRef.set({
        'codigo': codigoFinal,
        'placeId': placeId,
        'placeName': placeName,
        'venueId': placeId,
        'venueName': placeName,
        'descuentoPorcentaje': descuentoPorcentaje ?? 10.0,
        'descripcion': descripcion ?? 'Premio por ser un cliente destacado',
        'creadoEn': FieldValue.serverTimestamp(),
        'usado': false,
        'usadoEn': null,
        'validoHasta': Timestamp.fromDate(validoHastaDate),
      });

      // Notificación push: Cloud Function sendGiftCouponNotification (Firestore trigger)
      // envía al cliente: "¡[Nombre del Bar] te ha premiado! 🎁"
      debugPrint('✅ Cupón creado: $codigoFinal para usuario $userId');
      return codigoFinal;
    } catch (e) {
      debugPrint('❌ Error creando cupón: $e');
      rethrow;
    }
  }

  /// Genera un código de cupón único
  /// 
  /// Formato: 8 caracteres alfanuméricos en mayúsculas
  static String _generarCodigoCupon() {
    final uuid = _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    return uuid;
  }

  /// Obtiene todos los cupones de un usuario
  ///
  /// [userId]: ID del usuario
  /// [collection]: Colección donde está el usuario ('usuarios' o 'users').
  ///   Usar BarPointsService._resolveUserRef o pasar el valor ya resuelto.
  ///
  /// Retorna un stream de los cupones del usuario
  static Stream<QuerySnapshot> obtenerCuponesUsuario(
    String userId, {
    String collection = 'usuarios',
  }) {
    final userRef =
        FirebaseFirestore.instance.collection(collection).doc(userId);
    
    return userRef.collection('mis_cupones')
        .where('usado', isEqualTo: false)
        .where('validoHasta', isGreaterThan: Timestamp.now())
        .orderBy('validoHasta')
        .orderBy('creadoEn', descending: true)
        .snapshots();
  }

  /// Marca un cupón como usado (con transacción para evitar doble uso)
  /// 
  /// [userId]: ID del usuario
  /// [cuponId]: ID del documento del cupón
  static Future<void> marcarCuponComoUsado({
    required String userId,
    required String cuponId,
  }) async {
    try {
      var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
      }

      final cuponRef = userRef.collection('mis_cupones').doc(cuponId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final cuponSnap = await transaction.get(cuponRef);
        if (!cuponSnap.exists) {
          throw Exception('Cupón no encontrado');
        }
        if (cuponSnap.data()?['usado'] == true) {
          throw Exception('Cupón ya fue utilizado');
        }

        transaction.update(cuponRef, {
          'usado': true,
          'usadoEn': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('✅ Cupón marcado como usado: $cuponId');
    } catch (e) {
      debugPrint('❌ Error marcando cupón como usado: $e');
      rethrow;
    }
  }

  /// Valida si un código de cupón ya fue usado por el usuario
  /// 
  /// Verifica en la subcolección cupones_usados del usuario si el código ya fue utilizado.
  /// Esto previene el reuso de cupones de un solo uso.
  /// 
  /// [userId]: ID del usuario
  /// [codigo]: Código del cupón a validar
  /// 
  /// Retorna true si el código ya fue usado, false si está disponible
  static Future<bool> codigoYaUsado({
    required String userId,
    required String codigo,
  }) async {
    try {
      // Buscar usuario en ambas colecciones
      var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
        userDoc = await userRef.get();
      }

      if (!userDoc.exists) {
        return false; // Usuario no existe, código no usado
      }

      final codigoNorm = normalizarCodigo(codigo);
      if (codigoNorm.isEmpty) return false;

      final usadoDoc = await userRef
          .collection('cupones_usados')
          .where('codigo', isEqualTo: codigoNorm)
          .limit(1)
          .get();

      return usadoDoc.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error validando código usado: $e');
      return true; // Fail-closed: ante error de red/DB, considerar usado para evitar doble gasto
    }
  }

  /// Registra el uso de un código de cupón en la subcolección cupones_usados
  /// 
  /// Esto crea un registro permanente de que el usuario utilizó este código,
  /// previniendo su reuso futuro.
  /// 
  /// [userId]: ID del usuario
  /// [codigo]: Código del cupón utilizado
  /// [orderId]: ID del pedido donde se usó el cupón
  /// [placeId]: ID del lugar donde se usó
  /// [descuentoAplicado]: Monto del descuento aplicado
  static Future<void> registrarUsoCupon({
    required String userId,
    required String codigo,
    required String orderId,
    required String placeId,
    double? descuentoAplicado,
  }) async {
    try {
      // Buscar usuario en ambas colecciones
      var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
        userDoc = await userRef.get();
      }

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado para registrar uso de cupón');
      }

      final codigoNorm = normalizarCodigo(codigo);
      if (codigoNorm.isEmpty) {
        throw Exception('Código inválido para registrar uso');
      }
      await userRef.collection('cupones_usados').add({
        'codigo': codigoNorm,
        'orderId': orderId,
        'placeId': placeId,
        'descuentoAplicado': descuentoAplicado,
        'usadoEn': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Uso de cupón registrado: $codigo para usuario $userId');
    } catch (e) {
      debugPrint('❌ Error registrando uso de cupón: $e');
      rethrow;
    }
  }

  /// Valida y aplica un código de cupón
  /// 
  /// Primero intenta validar contra cupones maestros (globales),
  /// luego contra cupones personales del usuario.
  /// 
  /// Verifica:
  /// 1. Si el código existe en cupones_maestros (globales) o en mis_cupones del usuario
  /// 2. Si el código ya fue usado (en cupones_usados)
  /// 3. Si el cupón está vigente (validoHasta)
  /// 
  /// [userId]: ID del usuario
  /// [codigo]: Código del cupón a validar
  /// [placeId]: ID del lugar donde se intenta usar (opcional, necesario para cupones maestros)
  /// 
  /// Retorna un mapa con:
  /// - 'valido': bool - Si el cupón es válido
  /// - 'descuentoPorcentaje': double - Porcentaje de descuento
  /// - 'mensaje': String - Mensaje de error o éxito
  static Future<Map<String, dynamic>> validarYCodigoCupon({
    required String userId,
    required String codigo,
    String? placeId,
    /// Datos del local (para validar cupones BarPoints: aceptaBarpoints, barpointsDisponiblesHoy)
    Map<String, dynamic>? placeData,
    /// true = pedido Delivery o Takeaway (BarPoints permitido), false = mesa física (BarPoints bloqueado)
    bool? isPedidoOnline,
  }) async {
    try {
      // 0. Normalizar código (mismo formato que BarPoints y globales)
      final codigoNorm = normalizarCodigo(codigo);
      if (codigoNorm.isEmpty) {
        return {'valido': false, 'mensaje': 'Ingresá un código de descuento.'};
      }
      if (!esFormatoCodigoValido(codigoNorm)) {
        return {
          'valido': false,
          'mensaje': 'El código solo puede tener letras y números (sin espacios ni caracteres especiales).',
        };
      }

      // 1. Primero intentar validar contra cupones maestros (globales)
      // Solo retornamos si es VÁLIDO; si no está en maestros, seguimos a mis_cupones (BarPoints/personales)
      if (placeId != null && placeId.isNotEmpty) {
        final validacionMaestro = await validarCuponMaestro(
          codigo: codigoNorm,
          placeId: placeId,
          userId: userId,
        );
        if (validacionMaestro['valido'] == true) {
          return validacionMaestro;
        }
        // Si no es cupón maestro (inválido, no encontrado, etc.), continuamos
        // a validar mis_cupones donde están los BarPoints y cupones personales
      }

      // 2. Validar cupones personales (mis_cupones: BarPoints + cupones regalados)
      final yaUsado = await codigoYaUsado(userId: userId, codigo: codigoNorm);
      if (yaUsado) {
        return {
          'valido': false,
          'mensaje': 'Este código ya lo usaste anteriormente. Recordá que los códigos de descuento son de un solo uso.',
        };
      }

      // 2. Resolver colección del usuario (users o usuarios)
      var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      var userDoc = await userRef.get();
      if (!userDoc.exists) {
        userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
        userDoc = await userRef.get();
      }
      if (!userDoc.exists) {
        return {'valido': false, 'mensaje': 'Usuario no encontrado'};
      }

      // 3. Buscar cupón por codigo (normalizado, campo 'codigo' en Firestore)
      // No filtramos por expiración en la query: validamos en código para soportar
      // fechaVencimiento (BarPoints 24h), validoHasta (legacy) y cupones sin fecha
      final cuponesSnapshot = await userRef
          .collection('mis_cupones')
          .where('codigo', isEqualTo: codigoNorm)
          .where('usado', isEqualTo: false)
          .get();

      if (cuponesSnapshot.docs.isEmpty) {
        return {
          'valido': false,
          'mensaje': 'Código no encontrado en tus cupones. Verificá que lo hayas escrito bien.',
        };
      }

      final doc = cuponesSnapshot.docs.first;
      final cuponData = doc.data();
      final now = Timestamp.now();

      // 4. Validar expiración: fechaVencimiento (BarPoints 24h) > validoHasta > sin campo
      final fechaVenc = cuponData['fechaVencimiento'] as Timestamp?;
      final validoHasta = cuponData['validoHasta'] as Timestamp?;
      final bool expirado = (fechaVenc != null && fechaVenc.compareTo(now) <= 0) ||
          (fechaVenc == null && validoHasta != null && validoHasta.compareTo(now) <= 0);
      if (expirado) {
        final esBarpoints = cuponData['origenBarpoints'] == true;
        return {
          'valido': false,
          'mensaje': esBarpoints
              ? 'El código expiró después de las 24hs. Canjeá de nuevo para obtener uno nuevo.'
              : 'El código de cupón ya expiró.',
        };
      }

      final descuentoPorcentaje = (cuponData['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;

      // Cupones BarPoints: solo válidos en pedidos online y si el local acepta hoy
      if (cuponData['origenBarpoints'] == true) {
        if (isPedidoOnline == false) {
          return {
            'valido': false,
            'mensaje': 'Los BarPoints solo son canjeables en pedidos Delivery o Retiro, no en mesa.',
          };
        }
        if (placeId != null && placeId.isNotEmpty && placeData != null) {
          if (placeData['aceptaBarpoints'] != true) {
            return {
              'valido': false,
              'mensaje': 'Este local no acepta BarPoints.',
            };
          }
          if (placeData['barpointsDisponiblesHoy'] != true) {
            return {
              'valido': false,
              'mensaje': 'Los BarPoints no están disponibles hoy en este local.',
            };
          }
        }
      }

      // Cupones de regalo (premio): válidos solo en el local que los emitió
      final cuponVenueId = cuponData['venueId'] as String? ?? cuponData['placeId'] as String?;
      final cuponVenueName = cuponData['venueName'] as String? ?? cuponData['placeName'] as String? ?? 'este local';
      if (cuponVenueId != null &&
          cuponVenueId.isNotEmpty &&
          placeId != null &&
          placeId.isNotEmpty &&
          cuponVenueId != placeId) {
        return {
          'valido': false,
          'mensaje': 'Este cupón de regalo es exclusivo para consumos en $cuponVenueName.',
        };
      }

      return {
        'valido': true,
        'descuentoPorcentaje': descuentoPorcentaje,
        'cuponId': doc.id,
        'origenBarpoints': cuponData['origenBarpoints'] == true,
        'mensaje': 'Código aplicado correctamente',
      };
    } catch (e) {
      debugPrint('❌ Error validando código de cupón: $e');
      return {
        'valido': false,
        'mensaje': 'No pudimos validar el código. Verificá tu conexión e intentá de nuevo.',
      };
    }
  }

  /// Crea un cupón maestro global (para Superadmin)
  /// 
  /// Los cupones maestros se guardan en la colección 'cupones_maestros'
  /// y pueden ser usados por cualquier usuario según su alcance y tipo de uso.
  /// 
  /// [codigo]: Código del cupón (debe ser único)
  /// [descuentoPorcentaje]: Porcentaje de descuento (5-50%)
  /// [alcance]: 'global' o 'especifico'
  /// [placeIds]: Lista de IDs de lugares (solo si alcance es 'especifico')
  /// [usoUnicoGlobal]: true = un solo uso en toda la app, false = un solo uso por bar
  static Future<void> crearCuponMaestro({
    required String codigo,
    required double descuentoPorcentaje,
    required String alcance,
    List<String>? placeIds,
    required bool usoUnicoGlobal,
  }) async {
    try {
      final codigoNorm = normalizarCodigo(codigo);
      if (codigoNorm.isEmpty || !esFormatoCodigoValido(codigoNorm)) {
        throw Exception('Código inválido. Solo letras y números (3-50 caracteres).');
      }

      final existing = await FirebaseFirestore.instance
          .collection('cupones_maestros')
          .where('codigo', isEqualTo: codigoNorm)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Ya existe un cupón activo con este código');
      }

      await FirebaseFirestore.instance.collection('cupones_maestros').add({
        'codigo': codigoNorm,
        'descuentoPorcentaje': descuentoPorcentaje,
        'alcance': alcance,
        'placeIds': alcance == 'especifico' ? (placeIds ?? []) : null,
        'usoUnicoGlobal': usoUnicoGlobal,
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
        'usadoCount': 0,
      });

      debugPrint('✅ Cupón maestro creado: $codigoNorm');
    } catch (e) {
      debugPrint('❌ Error creando cupón maestro: $e');
      rethrow;
    }
  }

  /// Valida un código de descuento en contexto de MESA FÍSICA (POS).
  /// Los cupones BarPoints se rechazan explícitamente.
  /// Solo acepta cupones maestros; los cupones personales deben usarse desde la app.
  static Future<Map<String, dynamic>> validarCodigoParaMesa({
    required String codigo,
    required String placeId,
  }) async {
    try {
      final codigoNorm = normalizarCodigo(codigo);
      if (codigoNorm.isEmpty || !esFormatoCodigoValido(codigoNorm)) {
        return {
          'valido': false,
          'mensaje': 'Ingresá un código válido (letras y números, sin espacios).',
        };
      }

      // 1. Rechazar explícitamente cupones BarPoints (collectionGroup)
      final barpointsSnap = await FirebaseFirestore.instance
          .collectionGroup('mis_cupones')
          .where('codigo', isEqualTo: codigoNorm)
          .where('origenBarpoints', isEqualTo: true)
          .limit(1)
          .get();

      if (barpointsSnap.docs.isNotEmpty) {
        return {
          'valido': false,
          'mensaje': 'Los BarPoints solo son canjeables en pedidos Delivery o Retiro, no en mesa.',
        };
      }

      // 2. Intentar cupón maestro (usamos placeId como userId sintético para "uso por bar")
      return await validarCuponMaestro(
        codigo: codigoNorm,
        placeId: placeId,
        userId: 'mesa_$placeId',
      );
    } catch (e) {
      debugPrint('❌ Error validando código para mesa: $e');
      return {'valido': false, 'mensaje': 'Error al validar código'};
    }
  }

  /// Desactiva un cupón maestro
  /// 
  /// [cuponId]: ID del documento del cupón maestro
  static Future<void> desactivarCuponMaestro(String cuponId) async {
    try {
      await FirebaseFirestore.instance
          .collection('cupones_maestros')
          .doc(cuponId)
          .update({
        'activo': false,
        'desactivadoEn': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Cupón maestro desactivado: $cuponId');
    } catch (e) {
      debugPrint('❌ Error desactivando cupón maestro: $e');
      rethrow;
    }
  }

  /// Valida un código de cupón maestro contra el bar actual
  /// 
  /// Verifica:
  /// 1. Si el código existe en cupones_maestros y está activo
  /// 2. Si el alcance permite usarlo en este bar
  /// 3. Si el tipo de uso permite usarlo (global o por bar)
  /// 4. Si el usuario ya lo usó (según el tipo de uso)
  /// 
  /// [codigo]: Código del cupón
  /// [placeId]: ID del lugar donde se intenta usar
  /// [userId]: ID del usuario que intenta usarlo
  /// 
  /// Retorna un mapa con la validación
  static Future<Map<String, dynamic>> validarCuponMaestro({
    required String codigo,
    required String placeId,
    required String userId,
  }) async {
    try {
      // 1. Buscar cupón maestro activo (código ya normalizado por caller)
      final codigoNorm = normalizarCodigo(codigo);
      final cuponesSnapshot = await FirebaseFirestore.instance
          .collection('cupones_maestros')
          .where('codigo', isEqualTo: codigoNorm)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (cuponesSnapshot.docs.isEmpty) {
        return {
          'valido': false,
          'mensaje': 'Código de cupón inválido o expirado',
        };
      }

      final cuponData = cuponesSnapshot.docs.first.data();
      final alcance = cuponData['alcance'] as String? ?? 'global';
      final usoUnicoGlobal = cuponData['usoUnicoGlobal'] == true;
      final placeIds = (cuponData['placeIds'] as List?)?.cast<String>() ?? [];

      // 2. Verificar alcance
      if (alcance == 'especifico' && !placeIds.contains(placeId)) {
        return {
          'valido': false,
          'mensaje': 'Este cupón no es válido para este bar',
        };
      }

      // 3. Verificar uso según tipo
      if (usoUnicoGlobal) {
        final yaUsado = await codigoYaUsado(userId: userId, codigo: codigoNorm);
        if (yaUsado) {
          return {
            'valido': false,
            'mensaje': 'Este código ya lo usaste anteriormente. Recordá que los códigos de descuento son de un solo uso.',
          };
        }
      } else {
        // Un solo uso por bar
        var userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        var userDoc = await userRef.get();
        if (!userDoc.exists) {
          userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
          userDoc = await userRef.get();
        }

        if (userDoc.exists) {
          final usadoEnEsteBar = await userRef
              .collection('cupones_usados')
              .where('codigo', isEqualTo: codigoNorm)
              .where('placeId', isEqualTo: placeId)
              .limit(1)
              .get();

          if (usadoEnEsteBar.docs.isNotEmpty) {
            return {
              'valido': false,
              'mensaje': 'Ya usaste este cupón en este bar anteriormente',
            };
          }
        }
      }

      // 4. Todo OK, retornar datos del cupón
      final descuentoPorcentaje = (cuponData['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;

      return {
        'valido': true,
        'descuentoPorcentaje': descuentoPorcentaje,
        'cuponMaestroId': cuponesSnapshot.docs.first.id,
        'mensaje': 'Código aplicado correctamente',
      };
    } catch (e) {
      debugPrint('❌ Error validando cupón maestro: $e');
      return {
        'valido': false,
        'mensaje': 'Error al validar el código de cupón',
      };
    }
  }
}
