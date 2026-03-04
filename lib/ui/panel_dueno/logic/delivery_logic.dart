import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barapp/services/printer/printer_service.dart';
import 'package:barapp/services/coupons_service.dart';
import 'package:barapp/ui/panel_dueno/widgets/delivery/client_rating_dialog.dart';

/// Mixin que contiene la lógica de negocio unificada para el sistema de delivery
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin DeliveryLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Variable de estado para controlar el loading (debe ser manejada por el widget)
  bool isLoading = false;

  /// Obtiene el stream de pedidos según los parámetros proporcionados
  /// 
  /// [isActive]: Si es true, retorna pedidos activos. Si es false, retorna historial.
  /// [userRol]: Rol del usuario ('admin' o 'repartidor')
  /// [userEmail]: Email del usuario (requerido si userRol es 'repartidor')
  /// 
  /// IMPORTANTE: Este método filtra automáticamente para excluir pedidos de salón (mesas físicas).
  /// Solo muestra pedidos de la app web (delivery/retiro) que tienen el campo 'metodoEntrega'.
  Stream<QuerySnapshot> getOrdersStream({
    required bool isActive,
    String? userRol,
    String? userEmail,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('orders');

    // 🔥 FILTRO CRÍTICO: Excluir pedidos de salón (mesas físicas)
    // Los pedidos de salón NO tienen 'metodoEntrega', solo los de app web lo tienen
    query = query.where('metodoEntrega', whereIn: ['delivery', 'retiro']);

    // Filtrar por estado según si es activo o historial
    if (isActive) {
      query = query.where('estado', whereIn: [
        'pendiente',
        'confirmado',
        'en_preparacion',
        'preparado',
        'en_camino',
        'listo_para_retirar',
      ]);
    } else {
      query = query.where('estado', whereIn: [
        'entregado',
        'rechazado',
        'error',
      ]);
    }

    // Si es repartidor, filtrar por su email
    if (userRol == 'repartidor' && userEmail != null) {
      query = query.where('driverEmail', isEqualTo: userEmail);
    }

    return query.snapshots();
  }

  /// Obtiene el stream de repartidores (choferes)
  Stream<QuerySnapshot> getDriversStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('staff')
        .where('rol', isEqualTo: 'repartidor')
        .snapshots();
  }

  /// Setter para actualizar el estado de loading
  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
      });
    }
  }

  /// Acepta un pedido y lo envía a cocina
  /// 
  /// Si autoPrintComandas está activado, imprime la comanda automáticamente.
  /// Actualiza el estado del pedido a 'en_preparacion'.
  Future<void> acceptOrder({
    required String orderId,
    required String metodoEntrega,
    Map<String, dynamic>? orderData,
  }) async {
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (orderData != null && (prefs.getBool('autoPrintComandas') ?? false)) {
        await _printComanda(orderData, metodoEntrega);
      }

      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId)
          .update({
        'estado': 'en_preparacion',
        'requiereCocina': true,
        'cocinaIniciadoAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error aceptando pedido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Envía un pedido a cocina creando una comanda
  /// 
  /// Crea una comanda en la colección 'comandas' y actualiza el estado del pedido.
  Future<void> mandarACocina({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    setLoading(true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('comandas')
          .add({
        'items': orderData['items'] ?? [],
        'mesaNombre': orderData['metodoEntrega'] == 'retiro'
            ? 'RETIRO'
            : 'DELIVERY',
        'estado': 'pendiente',
        'timestamp': FieldValue.serverTimestamp(),
        'origen': 'delivery',
        'orderId': orderId,
      });

      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId)
          .update({'estado': 'en_preparacion'});
    } catch (e) {
      debugPrint("Error mandando a cocina: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Marca un pedido como preparado
  /// 
  /// Si es retiro, pasa a 'listo_para_retirar'.
  /// Si es delivery, pasa a 'preparado' para esperar asignación de chofer.
  /// Si autoPrintCliente está activado, imprime el ticket automáticamente.
  Future<void> markAsPrepared({
    required String orderId,
    required String metodoEntrega,
    Map<String, dynamic>? orderData,
  }) async {
    setLoading(true);
    try {
      if (metodoEntrega == 'retiro') {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('autoPrintCliente') == true && orderData != null) {
          await _printCliente({...orderData, 'orderId': orderId});
        }
        await _updateStatus(orderId, 'listo_para_retirar');
      } else {
        await _updateStatus(orderId, 'preparado');
      }
    } catch (e) {
      debugPrint("Error marcando como preparado: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Asigna un chofer a un pedido
  /// 
  /// Actualiza el pedido con los datos del chofer y cambia el estado a 'en_camino'.
  /// Si autoPrintCliente está activado, imprime el ticket automáticamente.
  Future<void> assignDriver({
    required String orderId,
    required QueryDocumentSnapshot driverDoc,
    Map<String, dynamic>? orderData,
  }) async {
    setLoading(true);
    try {
      final driverData = driverDoc.data() as Map<String, dynamic>;
      final String emailChofer = driverData['email'] ?? '';
      final String nombreChofer = driverData['nombre'] ?? 'Sin Nombre';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('autoPrintCliente') == true && orderData != null) {
        await _printCliente({...orderData, 'orderId': orderId});
      }

      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId)
          .update({
        'estado': 'en_camino',
        'driverId': driverDoc.id,
        'driverName': nombreChofer,
        'driverEmail': emailChofer,
        'dispatchedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error asignando chofer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Finaliza un pedido y crea la venta correspondiente usando BATCH atómico
  /// 
  /// CRÍTICO: Usa Batch para garantizar atomicidad. Si falla cualquier operación,
  /// ninguna se ejecuta, evitando duplicados o pérdida de datos.
  /// 
  /// Obtiene los datos más recientes del pedido antes de procesar para evitar
  /// inconsistencias.
  Future<void> finalizeAndMoveToSales({
    required String orderId,
    Map<String, dynamic>? orderData,
  }) async {
    setLoading(true);
    try {
      // Referencia al pedido original
      final orderRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId);

      // TRANSACCIÓN ATÓMICA: leer → verificar estado → actualizar + crear venta
      // Previene duplicados si se llama dos veces simultáneamente.
      final freshData = await FirebaseFirestore.instance.runTransaction<Map<String, dynamic>?>((transaction) async {
        final freshSnap = await transaction.get(orderRef);

        if (!freshSnap.exists) return null;

        final data = freshSnap.data()!;
        if (data['estado'] == 'entregado') {
          throw Exception('already-delivered');
        }

        // Sanitización de datos numéricos
        final double totalFinal = (data['total'] as num?)?.toDouble() ?? 0.0;
        final double costoEnvio = (data['costoEnvio'] as num? ?? 0.0).toDouble();
        final double totalComida = (data['totalComida'] as num?)?.toDouble() ?? (totalFinal - costoEnvio);

        final String metodoEntrega = data['metodoEntrega'] ?? 'retiro';
        final String metodoPago = (data['metodoPago'] ?? 'efectivo').toString().toLowerCase();
        final String repartidorId = (metodoEntrega == 'retiro')
            ? 'MOSTRADOR'
            : (data['driverEmail'] ?? 'SIN_ASIGNAR');

        // Referencia a la nueva venta
        final saleRef = FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('ventas')
            .doc();

        transaction.update(orderRef, {
          'estado': 'entregado',
          'entregadoAt': FieldValue.serverTimestamp(),
        });

        final Map<String, dynamic> ventaPayload = {
          'fecha': FieldValue.serverTimestamp(),
          'total': totalFinal,
          'totalComida': totalComida,
          'totalEnvio': costoEnvio,
          'repartidor': repartidorId,
          'mesa': 'App-Bar',
          'origen': 'app',
          'metodoPrincipal': metodoPago,
          'items': data['items'] ?? [],
          'pagos': [
            {'metodo': metodoPago, 'monto': totalFinal, 'tipo': 'total'}
          ],
          'orderId': orderId,
          'cliente': data['clienteNombre'] ?? 'Cliente App',
        };

        // Incluir datos de descuento/cupón si los hay (para reportes)
        if (data['descuentoAplicado'] != null) {
          ventaPayload['descuentoAplicado'] = data['descuentoAplicado'];
        }
        if (data['codigoDescuento'] != null && (data['codigoDescuento'] as String).isNotEmpty) {
          ventaPayload['codigoDescuento'] = data['codigoDescuento'];
        }

        transaction.set(saleRef, ventaPayload);

        return data;
      });

      if (freshData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El pedido no existe"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // BarPoints: La Cloud Function onOrderDelivered se dispara automáticamente
      // al detectar estado 'entregado' y acredita los puntos con Admin SDK (máxima seguridad).

      // ============================================================
      // REGISTRAR USO DE CUPÓN (si se aplicó uno)
      // Solo para cupones maestros (globales): los cupones personales (cuponId presente)
      // ya fueron atomicamente registrados en cupones_usados al crear el pedido.
      // ============================================================
      final String? userId = freshData['userId'] as String?;
      final String? codigoDescuento = freshData['codigoDescuento'] as String?;
      final double? descuentoAplicado = (freshData['descuentoAplicado'] as num?)?.toDouble();
      final bool cuponYaRegistrado = freshData['cuponId'] != null;
      
      if (userId != null && userId.isNotEmpty &&
          codigoDescuento != null && codigoDescuento.isNotEmpty &&
          !cuponYaRegistrado) {
        try {
          await CouponsService.registrarUsoCupon(
            userId: userId,
            codigo: codigoDescuento,
            orderId: orderId,
            placeId: placeId,
            descuentoAplicado: descuentoAplicado,
          );
          debugPrint('✅ Uso de cupón maestro registrado: $codigoDescuento');
        } catch (e) {
          debugPrint('⚠️ Error registrando uso de cupón (no crítico): $e');
          // No bloqueamos el flujo si falla el registro
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Venta registrada correctamente"),
            backgroundColor: Colors.green,
          ),
        );

        // ============================================================
        // MOSTRAR DIÁLOGO DE CALIFICACIÓN AL CLIENTE
        // ============================================================
        // Si el pedido es de un cliente registrado, mostrar diálogo para calificarlo
        if (userId != null && userId.isNotEmpty) {
          final clienteNombre = freshData['clienteNombre'] ?? 'Cliente';
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ClientRatingDialog(
                userId: userId,
                orderId: orderId,
                placeId: placeId,
                clienteNombre: clienteNombre.toString(),
              ),
            );
          }
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('already-delivered')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Este pedido ya fue entregado"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        debugPrint("🔥 Error crítico al finalizar venta: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al finalizar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setLoading(false);
    }
  }

  /// Abre WhatsApp con un ticket formateado del pedido
  /// 
  /// Construye un mensaje formateado con los detalles del pedido y lo envía por WhatsApp.
  Future<void> openWhatsAppTicket({
    required String phone,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

      final cliente = orderData['clienteNombre'] ?? 'Cliente';
      final items = (orderData['items'] as List?) ?? [];
      final total = (orderData['total'] as num?)?.toDouble() ?? 0.0;
      final envio = (orderData['costoEnvio'] as num?)?.toDouble() ?? 0.0;
      final fecha = (orderData['createdAt'] as Timestamp?)?.toDate();
      final hora = fecha != null ? DateFormat('dd/MM HH:mm').format(fecha) : '-';

      // Construcción del mensaje usando %0A para saltos de línea en URL encoding
      StringBuffer msg = StringBuffer();
      msg.write("Hola *$cliente*! 👋 Te envío el detalle de tu pedido en *BarApp*:%0A%0A");
      msg.write("🧾 *TICKET DE PEDIDO* 🧾%0A");
      msg.write("📅 Fecha: $hora%0A");
      msg.write("--------------------------------%0A");

      for (var item in items) {
        final cant = item['cantidad'] ?? 1;
        final nombre = item['nombre'] ?? 'Producto';
        final precio = (item['precio'] as num? ?? 0.0).toDouble();
        final precioTotal = (precio * cant).toStringAsFixed(0);
        msg.write("▪️ ${cant}x $nombre (\$ $precioTotal)%0A");
      }

      msg.write("--------------------------------%0A");
      if (envio > 0) {
        msg.write("🛵 Envío: \$ ${envio.toStringAsFixed(0)}%0A");
      }
      msg.write("💰 *TOTAL: \$ ${NumberFormat("#,##0", "es_AR").format(total)}*%0A");
      msg.write("--------------------------------%0A");
      msg.write("✅ _Gracias por tu compra. Tu pedido está en camino._");

      final url = "https://wa.me/$cleanPhone?text=${msg.toString()}";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo abrir WhatsApp")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error abriendo WhatsApp: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al abrir WhatsApp")),
        );
      }
    }
  }

  /// Actualiza el estado de un pedido
  Future<void> updateStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .doc(orderId)
          .update({'estado': status});
    } catch (e) {
      debugPrint("Error actualizando estado: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Actualiza el estado de un pedido (método privado usado internamente)
  Future<void> _updateStatus(String orderId, String status) async {
    await updateStatus(orderId, status);
  }

  /// Imprime la comanda de cocina manualmente
  Future<void> printComanda(Map<String, dynamic> orderData) async {
    await _printComanda(orderData, orderData['metodoEntrega'] ?? 'delivery');
  }

  /// Imprime el ticket del cliente manualmente
  Future<void> printCliente(Map<String, dynamic> orderData) async {
    await _printCliente(orderData);
  }

  /// Imprime la comanda de cocina
  Future<void> _printComanda(
    Map<String, dynamic> orderData,
    String metodoEntrega,
  ) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🖨️ Imprimiendo Comanda..."),
            duration: Duration(seconds: 1),
          ),
        );
      }
      await PrinterService().printComanda({
        ...orderData,
        'origen': 'app',
        'mesaNombre': metodoEntrega == 'delivery' ? 'DELIVERY' : 'RETIRO',
      });
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  /// Imprime el ticket del cliente
  Future<void> _printCliente(Map<String, dynamic> orderData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🖨️ Imprimiendo Ticket..."),
            duration: Duration(seconds: 1),
          ),
        );
      }
      final telefonoVal = orderData['clienteTelefono'] ?? orderData['telefono'];
      final telefonoTicket = (telefonoVal != null &&
              telefonoVal.toString().trim().isNotEmpty &&
              telefonoVal.toString().toLowerCase() != 'null')
          ? telefonoVal.toString()
          : 'S/D';
      await PrinterService().printTicket({
        ...orderData,
        'tipoTicket': 'PEDIDO_CLIENTE',
        'orderId': orderData['orderId'] ?? orderData['id'],
        'cliente': orderData['clienteNombre'] ?? 'Cliente',
        'telefono': telefonoTicket,
        'direccion': orderData['direccion'] ?? 'Retira',
        'total': (orderData['total'] as num?)?.toDouble() ?? 0.0,
        'costoEnvio': (orderData['costoEnvio'] as num?)?.toDouble() ?? 0.0,
      });
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }
}
