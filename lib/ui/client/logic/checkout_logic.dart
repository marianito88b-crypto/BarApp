import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../client_orders_screen.dart';
import '../../../services/barpoints_service.dart';
import '../../../services/coupons_service.dart';

/// Mixin que contiene la lógica de negocio para el proceso de checkout
///
/// Requiere que la clase que lo use implemente:
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin CheckoutLogicMixin<T extends StatefulWidget> on State<T> {
  /// Obtiene la distancia en kilómetros entre la ubicación del usuario y el lugar
  /// 
  /// Retorna 0.0 si:
  /// - El lugar no tiene coordenadas GPS configuradas
  /// - El usuario no otorga permisos de ubicación
  /// - Ocurre un error al obtener la ubicación
  Future<double> obtenerDistanciaEnKm(Map<String, dynamic> placeData) async {
    // Si el bar no tiene GPS configurado, devolvemos 0 (Costo Base)
    if (placeData['lat'] == null || placeData['lng'] == null) return 0.0;

    try {
      // Verificar permisos del cliente
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return 0.0; // Fallback
      }

      // Posición del Cliente
      Position userPos = await Geolocator.getCurrentPosition();

      // Posición del Bar
      double barLat = (placeData['lat'] as num).toDouble();
      double barLng = (placeData['lng'] as num).toDouble();

      // Cálculo de distancia (en metros)
      double distanciaMetros = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        barLat,
        barLng,
      );

      return distanciaMetros / 1000; // Retornamos KM
    } catch (e) {
      debugPrint("Error GPS Cliente: $e");
      return 0.0; // Fallback ante error
    }
  }

  /// Calcula el costo de envío basado en la distancia y la configuración del lugar
  /// 
  /// [distanciaKm]: Distancia en kilómetros entre el usuario y el lugar
  /// [configEnvio]: Mapa con la configuración de envío del lugar
  /// 
  /// Retorna 0.0 si el envío es gratis, o el costo calculado según la distancia.
  double calcularCostoEnvio({
    required double distanciaKm,
    required Map<String, dynamic> configEnvio,
  }) {
    if (configEnvio['envioGratis'] == true) return 0.0;

    double base = (configEnvio['envioCostoBase'] ?? 2000).toDouble();
    double extra = (configEnvio['envioCostoKmExtra'] ?? 500).toDouble();

    if (distanciaKm <= 1.0) {
      return base;
    } else {
      double kmAdicionales = (distanciaKm - 1.0).ceilToDouble();
      return base + (kmAdicionales * extra);
    }
  }

  /// Sanitiza y normaliza un número de teléfono para Argentina
  /// 
  /// Esta función:
  /// - Elimina espacios, guiones, paréntesis y el símbolo +
  /// - Agrega el código de país "54" al inicio si no lo tiene
  /// - Retorna solo dígitos (formato: "5493624112233")
  /// 
  /// [phone]: Número de teléfono ingresado por el usuario
  /// 
  /// Retorna el número normalizado o null si el número es inválido (menos de 10 dígitos).
  String? sanitizePhoneNumber(String phone) {
    if (phone.trim().isEmpty) return null;

    // 1. Eliminar todos los caracteres no numéricos (espacios, guiones, paréntesis, +)
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Si está vacío después de limpiar, retornar null
    if (cleaned.isEmpty) return null;

    // 3. Si NO empieza con "54", agregarlo al inicio
    if (!cleaned.startsWith('54')) {
      cleaned = '54$cleaned';
    }

    // 4. Validación: debe tener al menos 10 dígitos (54 + código de área + número)
    // Un número argentino válido con código de país tiene mínimo: 54 (país) + 9 (móvil) + código área (2-4 dígitos) + número (6-8 dígitos)
    // Mínimo razonable: 54 + 9 + 2 + 6 = 13 dígitos
    // Pero aceptamos desde 10 para ser más permisivos con números locales que luego se normalizan
    if (cleaned.length < 10) {
      return null;
    }

    return cleaned;
  }

  /// Envía el pedido a Firestore y navega a la pantalla de pedidos
  /// 
  /// MEJORA DE SEGURIDAD: Verifica que el usuario esté autenticado antes de proceder.
  /// 
  /// [placeId]: ID del lugar
  /// [cart]: Mapa con los items del carrito
  /// [placeWhatsapp]: Número de WhatsApp del lugar
  /// [total]: Total final del pedido
  /// [placeName]: Nombre del lugar
  /// [isDelivery]: Si el pedido es delivery o retiro
  /// [paymentMethod]: Método de pago seleccionado
  /// [bankData]: Datos bancarios (alias, cbu, banco)
  /// [address]: Dirección de entrega (si es delivery)
  /// [phone]: Teléfono del cliente
  /// [notes]: Notas para la cocina
  /// [subtotal]: Subtotal de productos (sin envío)
  /// [shippingCost]: Costo de envío calculado
  /// [discountCode]: Código de descuento aplicado (opcional)
  /// [discountAmount]: Monto del descuento aplicado (opcional)
  /// [cuponId]: ID del cupón usado (opcional, para registro de uso)
  /// 
  /// Retorna el ID del pedido creado si fue exitoso, null en caso contrario.
  Future<String?> submitOrder({
    required String placeId,
    required Map<String, Map<String, dynamic>> cart,
    required String placeWhatsapp,
    required double total,
    required String placeName,
    required bool isDelivery,
    required String paymentMethod,
    required Map<String, String> bankData,
    required String address,
    required String phone,
    required String notes,
    required double subtotal,
    required double shippingCost,
    String? discountCode,
    double? discountAmount,
    double? discountPorcentaje,
    bool origenBarpoints = false,
    String? cuponId,
  }) async {
    // MEJORA DE SEGURIDAD: Verificar autenticación
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Debes iniciar sesión para realizar un pedido"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    try {
      // Obtener datos del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final String userName =
          userData['displayName'] ?? user.displayName ?? 'Cliente App';

      // Procesamiento de items
      final List<Map<String, dynamic>> itemsProcesados = cart.entries.map((e) {
        final item = e.value;
        return {
          'productoId': e.key,
          'nombre': item['nombre'],
          'precio': item['precio'],
          'cantidad': item['cantidad'],
          'controlaStock': item['controlaStock'] ?? false,
        };
      }).toList();

      // ============================================================
      // CALCULAR BARPOINTS ESTIMADOS
      // ============================================================
      // Calculamos los puntos que ganará el usuario cuando el pedido se complete
      // Fórmula: 1 punto por cada 1000 ARS del total
      final int puntosEstimados = BarPointsService.calcularPuntosEstimados(total);

      // Sanitizar y normalizar el número de teléfono
      final String? phoneSanitized = sanitizePhoneNumber(phone);
      if (phoneSanitized == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ El número de teléfono es inválido. Debe tener al menos 10 dígitos."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Redondeo seguro a 2 decimales (evita errores en pasarelas de pago)
      final totalRedondeado = _redondearMoneda(total);
      final subtotalRedondeado = _redondearMoneda(subtotal);
      final descuentoRedondeado = discountAmount != null ? _redondearMoneda(discountAmount) : 0.0;
      final envioRedondeado = _redondearMoneda(isDelivery ? shippingCost : 0);

      final orderData = {
        'userId': user.uid,
        'clienteNombre': userName,
        'placeId': placeId,
        'placeName': placeName,
        'items': itemsProcesados,
        'total': totalRedondeado,
        'clienteTelefono': phoneSanitized, // Usar el número sanitizado
        'costoEnvio': envioRedondeado,
        'totalComida': subtotalRedondeado,
        'metodoEntrega': isDelivery ? 'delivery' : 'retiro',
        'direccion': isDelivery ? address : null,
        'metodoPago': paymentMethod,
        'notas': notes,
        'estado': 'pendiente', // Estado inicial correcto
        'createdAt': FieldValue.serverTimestamp(),
        'origen': 'app',
        'canal': 'app',
        // ============================================================
        // BARPOINTS: Puntos estimados que se acreditarán al completar
        // ============================================================
        'puntosEstimados': puntosEstimados,
        'puntosAcreditados': false, // Flag para prevenir duplicación
        // ============================================================
        // CUPÓN DE DESCUENTO (si se aplicó)
        // ============================================================
        if (discountCode != null && discountCode.isNotEmpty) 'codigoDescuento': discountCode,
        if (descuentoRedondeado > 0) 'descuentoAplicado': descuentoRedondeado,
        if (discountPorcentaje != null) 'descuentoPorcentaje': discountPorcentaje,
        if (origenBarpoints) 'origenBarpoints': true,
        // Almacenamos cuponId para que finalizeAndMoveToSales detecte que ya fue
        // registrado atómicamente al crear el pedido y no duplique cupones_usados.
        if (cuponId != null) 'cuponId': cuponId,
      };

      String? orderId;

      final useCupon = (discountCode != null && discountCode.isNotEmpty && cuponId != null);

      if (useCupon) {
        // TRANSACCIÓN ATÓMICA: crear pedido + marcar cupón usado + registrar uso
        // Previene doble gasto si dos pedidos se envían simultáneamente con el mismo cupón
        orderId = await _submitOrderWithCuponAtomically(
          placeId: placeId,
          userId: user.uid,
          orderData: orderData,
          discountCode: discountCode,
          cuponId: cuponId,
          discountAmount: descuentoRedondeado,
        );
      } else {
        final orderDocRef = await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('orders')
            .add(orderData);
        orderId = orderDocRef.id;
      }

      if (orderId != null && mounted) {
        // Feedback Visual Rápido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ¡Pedido realizado con éxito!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // NAVEGACIÓN DIRECTA A "MIS PEDIDOS"
        // Usamos pushAndRemoveUntil para que el usuario no pueda volver atrás al checkout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ClientOrdersScreen()),
          (route) => route.isFirst,
        );
      }

      return orderId;
    } catch (e) {
      debugPrint("Error al enviar pedido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Redondea un monto a 2 decimales para evitar errores de precisión flotante
  static double _redondearMoneda(double value) {
    return (value * 100).round() / 100;
  }

  /// Transacción atómica: crea el pedido y marca el cupón como usado en una sola operación.
  /// Previene doble gasto de cupones.
  static Future<String?> _submitOrderWithCuponAtomically({
    required String placeId,
    required String userId,
    required Map<String, dynamic> orderData,
    required String discountCode,
    required String cuponId,
    required double discountAmount,
  }) async {
    final db = FirebaseFirestore.instance;
    final orderRef = db.collection('places').doc(placeId).collection('orders').doc();

    DocumentReference<Map<String, dynamic>>? userRef;
    for (final col in ['usuarios', 'users']) {
      final ref = db.collection(col).doc(userId);
      if ((await ref.get()).exists) {
        userRef = ref;
        break;
      }
    }
    if (userRef == null) return null;

    final cuponRef = userRef.collection('mis_cupones').doc(cuponId);

    try {
      await db.runTransaction((tx) async {
        // 1. Verificar que el cupón existe, NO está usado y es válido para este bar
        final cuponSnap = await tx.get(cuponRef);
        if (!cuponSnap.exists) {
          throw Exception('Cupón no encontrado');
        }
        final cuponData = cuponSnap.data();
        if (cuponData == null || (cuponData['usado'] as bool? ?? false)) {
          throw Exception('Este cupón ya fue utilizado');
        }
        // Exclusividad de venue: cupones de regalo solo en el bar que los emitió
        final cuponVenueId = cuponData['venueId'] as String? ?? cuponData['placeId'] as String?;
        if (cuponVenueId != null &&
            cuponVenueId.isNotEmpty &&
            cuponVenueId != placeId) {
          throw Exception('Este cupón no es válido para este local');
        }

        // 2. Crear pedido
        tx.set(orderRef, orderData);

        // 3. Marcar cupón como usado
        tx.update(cuponRef, {
          'usado': true,
          'usadoEn': FieldValue.serverTimestamp(),
        });

        // 4. Registrar uso en cupones_usados (evita reutilización)
        tx.set(userRef!.collection('cupones_usados').doc(), {
          'codigo': CouponsService.normalizarCodigo(discountCode),
          'orderId': orderRef.id,
          'placeId': placeId,
          'descuentoAplicado': discountAmount,
          'usadoEn': FieldValue.serverTimestamp(),
        });
      });
      return orderRef.id;
    } catch (e) {
      debugPrint('Error en transacción pedido+cupón: $e');
      rethrow;
    }
  }
}
