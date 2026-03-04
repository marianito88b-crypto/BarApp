import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/logic/mesas_logic.dart';
import 'package:barapp/ui/panel_dueno/widgets/pos/pos_utils.dart';
import 'package:barapp/ui/panel_dueno/pos/modal_procesar_pago.dart';
import 'package:barapp/services/printer/printer_service.dart';
import 'package:intl/intl.dart';

/// Mixin que contiene toda la lógica de negocio para el sistema POS de toma de pedidos
/// 
/// Requiere que la clase que lo use implemente:
/// - Getters: placeId, mesaId, mesaNombre
/// - Variables de estado: pedidoNuevo, pedidoHistorico, guardando, totalHistorico
/// - Métodos: setState, mounted (de State)
mixin TomaPedidoLogicMixin<T extends StatefulWidget> on State<T> {
  // Variables de estado que deben ser definidas en la clase que usa el mixin
  List<Map<String, dynamic>> get pedidoNuevo;
  List<Map<String, dynamic>> get pedidoHistorico;
  bool get guardando;
  double get totalHistorico;

  // Setters para actualizar el estado
  void setPedidoNuevo(List<Map<String, dynamic>> value);
  void setPedidoHistorico(List<Map<String, dynamic>> value);
  void setGuardando(bool value);
  void setTotalHistorico(double value);

  // Getters requeridos del widget
  String get placeId;
  String get mesaId;
  String get mesaNombre;

  // Suscripción de Firestore para cancelarla en dispose
  StreamSubscription<QuerySnapshot>? _pedidoSubscription;

  // Stream cacheado del menú para evitar re-creación en cada build
  late final Stream<QuerySnapshot> menuStream;

  // Stream cacheado de la mesa para evitar re-creación en cada build
  late final Stream<DocumentSnapshot> mesaStream;

  /// Inicializa la lógica del POS y carga el pedido existente
  void initTomaPedidoLogic() {
    debugPrint('🟢 initTomaPedidoLogic: placeId=$placeId mesaId=$mesaId');
    menuStream = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('menu')
        .orderBy('categoria')
        .snapshots();
    mesaStream = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('mesas')
        .doc(mesaId)
        .snapshots();
    _cargarPedidoExistente();
    debugPrint('🟢 initTomaPedidoLogic: streams cacheados OK');
  }

  /// Carga el pedido existente desde Firestore y mantiene una suscripción en tiempo real
  void _cargarPedidoExistente() {
    _pedidoSubscription = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('mesas')
        .doc(mesaId)
        .collection('cuenta_items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      debugPrint('🟡 cuenta_items: ${snap.docs.length} docs recibidos');
      double tempTotal = 0;
      List<Map<String, dynamic>> tempItems = [];

      for (var doc in snap.docs) {
        final data = {...doc.data(), 'docId': doc.id};
        double precio = PosUtils.safeDouble(data['precio']);
        int cant = PosUtils.safeInt(data['cantidad']);
        tempTotal += (precio * cant);
        tempItems.add(data);
      }

      if (mounted) {
        setState(() {
          setPedidoHistorico(tempItems);
          setTotalHistorico(tempTotal);
        });
      }
    }, onError: (e) {
      debugPrint('❌ Error en cuenta_items stream: $e');
    });
  }

  /// Elimina un item del pedido histórico y repone el stock si es necesario
  Future<void> eliminarItemHistorico(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Cancelar Item?", style: TextStyle(color: Colors.white)),
        content: Text("Se eliminará '${item['nombre']}' y se repondrá el stock."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sí, borrar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);

    final docRef = placeRef
        .collection('mesas')
        .doc(mesaId)
        .collection('cuenta_items')
        .doc(item['docId']);

    batch.delete(docRef);

    if (item['controlaStock'] == true && item['productoId'] != null) {
      final productoRef = placeRef.collection('menu').doc(item['productoId']);
      batch.update(productoRef, {
        'stock': FieldValue.increment(PosUtils.safeInt(item['cantidad'])),
      });
    }

    await batch.commit();
  }

  /// Marca el pedido y lo envía a cocina con transacción de seguridad para stock
  Future<void> marcharPedido() async {
    if (pedidoNuevo.isEmpty) return;

    setState(() => setGuardando(true));

    final firestore = FirebaseFirestore.instance;
    final placeRef = firestore.collection('places').doc(placeId);

    // 1. Sanitizamos los datos para evitar errores de tipo
    final List<Map<String, dynamic>> itemsLimpios = pedidoNuevo.map((item) {
      return {
        'productoId': item['productoId'].toString(),
        'nombre': item['nombre'].toString(),
        'cantidad': PosUtils.safeInt(item['cantidad']),
        'precio': PosUtils.safeDouble(item['precio']),
        'controlaStock': item['controlaStock'] == true,
      };
    }).toList();

    try {
      // 🔥 TRANSACCIÓN DE SEGURIDAD (Stock + Orden de Cocina)
      await firestore.runTransaction((tx) async {
        // A. Lectura de Stock (Paso obligatorio antes de escribir)
        for (final item in itemsLimpios) {
          if (item['controlaStock'] == true) {
            final prodRef = placeRef.collection('menu').doc(item['productoId']);
            final snap = await tx.get(prodRef);

            if (!snap.exists) {
              throw Exception("Producto ${item['nombre']} no existe");
            }

            final data = snap.data()!;
            final int stockActual = PosUtils.safeInt(data['stock']);
            final int cantidad = item['cantidad'];

            if (stockActual < cantidad) {
              throw Exception("Sin stock suficiente para: ${item['nombre']}");
            }

            // D. Descuento de Stock (En memoria de transacción)
            tx.update(prodRef, {
              'stock': stockActual - cantidad,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // B. Crear la Orden para COCINA (Colección 'orders')
        final orderRef = placeRef.collection('orders').doc();
        tx.set(orderRef, {
          'mesaId': mesaId,
          'mesaNombre': mesaNombre,
          'canal': 'salon',
          'origen': 'salon',
          'tipo': 'mesa', // Importante para filtros
          'estado': 'pendiente', // 👈 Cocina escucha esto
          'requiereCocina': true, // 👈 Forzamos que aparezca en cocina
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(), // Doble campo por seguridad
          'items': itemsLimpios,
        });
      });

      // 🔥 BATCH PARA ACTUALIZAR LA MESA (Fuera de transacción para velocidad)
      // Esto actualiza la cuenta visual de la mesa
      final batch = firestore.batch();
      final mesaRef = placeRef.collection('mesas').doc(mesaId);
      final itemsMesaRef = mesaRef.collection('cuenta_items');

      for (final item in itemsLimpios) {
        final docRef = itemsMesaRef.doc(); // Nuevo ID único para cada item en mesa
        batch.set(docRef, {
          ...item,
          'timestamp': FieldValue.serverTimestamp(),
          'estado': 'en_cocina',
        });
      }

      // Actualizar estado de la mesa a Ocupada
      batch.update(mesaRef, {
        'estado': 'ocupada',
        'fechaOcupacion': FieldValue.serverTimestamp(), // Si ya estaba ocupada no pasa nada
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // ✅ ÉXITO
      if (mounted) {
        setState(() {
          setPedidoNuevo([]);
          setGuardando(false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pedido enviado a cocina exitosamente"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Opcional: Cerrar pantalla si es celu chico
        if (MediaQuery.of(context).size.width < 900) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // ❌ ERROR (Stock o Conexión)
      if (mounted) {
        setState(() => setGuardando(false));

        String errorMsg = "Error al enviar pedido.";
        if (e.toString().contains("Sin stock")) {
          errorMsg = e.toString().replaceAll("Exception:", "").trim();
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("⚠️ No se pudo marchar",
                style: TextStyle(color: Colors.orangeAccent)),
            content: Text(errorMsg, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Entendido"),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Imprime la comanda de cocina con los productos nuevos
  Future<void> imprimirComandaCocina() async {
    if (pedidoNuevo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay ítems nuevos para imprimir.")),
      );
      return;
    }

    final datosPedido = {
      'mesaNombre': mesaNombre,
      'items': pedidoNuevo,
    };

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🖨️ Enviando a cocina..."),
          duration: Duration(seconds: 1),
        ),
      );
      await PrinterService().printComanda(datosPedido);
    } catch (e) {
      debugPrint("Error imprimiendo: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al imprimir"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Imprime la cuenta detallada del cliente con todos los items
  Future<void> imprimirCuentaCliente() async {
    final List<Map<String, dynamic>> itemsAImprimir = [
      ...pedidoHistorico,
      ...pedidoNuevo,
    ];

    if (itemsAImprimir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La mesa está vacía, nada que imprimir.")),
      );
      return;
    }

    final double totalGeneral = totalHistorico +
        pedidoNuevo.fold(
          0.0,
          (acc, item) =>
              acc +
              (PosUtils.safeDouble(item['precio']) *
                  PosUtils.safeInt(item['cantidad'])),
        );

    final datosTicket = {
      'mesaNombre': mesaNombre,
      'fecha': DateTime.now(),
      'items': itemsAImprimir,
      'total': totalGeneral,
      'esTicketCliente': true,
    };

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🖨️ Imprimiendo cuenta detallada..."),
          duration: Duration(seconds: 1),
        ),
      );
      await PrinterService().printTicket(datosTicket);
    } catch (e) {
      debugPrint("Error imprimiendo cuenta: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al imprimir ticket"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Obtiene las mesas relacionadas por reservaIdActiva (mismo grupo de reserva)
  Future<List<Map<String, dynamic>>> _obtenerMesasRelacionadas() async {
    try {
      // Obtener la mesa actual para ver si tiene reservaIdActiva
      final mesaActualSnap = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId)
          .get();
      
      final mesaActualData = mesaActualSnap.data();
      final reservaIdActiva = mesaActualData?['reservaIdActiva'];
      
      if (reservaIdActiva == null) {
        return []; // No hay reserva activa, no hay mesas relacionadas
      }

      // Buscar todas las mesas con el mismo reservaIdActiva
      final mesasRelacionadasSnap = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .where('reservaIdActiva', isEqualTo: reservaIdActiva)
          .get();

      final mesasRelacionadas = <Map<String, dynamic>>[];
      for (var doc in mesasRelacionadasSnap.docs) {
        if (doc.id != mesaId) { // Excluir la mesa actual
          final data = doc.data();
          mesasRelacionadas.add({
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Mesa',
            'estado': data['estado'] ?? 'libre',
          });
        }
      }

      return mesasRelacionadas;
    } catch (e) {
      debugPrint("Error obteniendo mesas relacionadas: $e");
      return [];
    }
  }

  /// Calcula el total de una mesa específica
  Future<double> _calcularTotalMesa(String mesaIdCalculo) async {
    try {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaIdCalculo)
          .collection('cuenta_items')
          .get();

      double total = 0.0;
      for (var doc in itemsSnapshot.docs) {
        final data = doc.data();
        final precio = PosUtils.safeDouble(data['precio']);
        final cantidad = PosUtils.safeInt(data['cantidad']);
        total += (precio * cantidad);
      }
      return total;
    } catch (e) {
      debugPrint("Error calculando total de mesa $mesaIdCalculo: $e");
      return 0.0;
    }
  }

  /// Cobra la cuenta y registra la venta en Firestore
  Future<void> cobrarCuenta() async {
    setState(() => setGuardando(true));

    try {
      final cajaQuery = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('caja_sesiones')
          .where('estado', isEqualTo: 'abierta')
          .limit(1)
          .get();

      if (cajaQuery.docs.isEmpty) {
        if (!mounted) return;
        setState(() => setGuardando(false));
        _mostrarAlertaCajaCerrada();
        return;
      }

      setState(() => setGuardando(false));

      final double totalGeneral = totalHistorico +
          pedidoNuevo.fold(
            0.0,
            (acc, item) =>
                acc +
                (PosUtils.safeDouble(item['precio']) *
                    PosUtils.safeInt(item['cantidad'])),
          );

      // 🔥 NUEVO: Detectar mesas relacionadas y ofrecer opción de cobro unificado
      final mesasRelacionadas = await _obtenerMesasRelacionadas();
      bool cobroUnificado = false;
      List<String> mesasACobrar = [mesaId];

      if (mesasRelacionadas.isNotEmpty) {
        // Calcular totales de todas las mesas relacionadas
        double totalUnificado = totalGeneral;
        final Map<String, double> totalesPorMesa = {mesaId: totalGeneral};

        for (var mesaRel in mesasRelacionadas) {
          final totalMesa = await _calcularTotalMesa(mesaRel['id']);
          totalesPorMesa[mesaRel['id']] = totalMesa;
          totalUnificado += totalMesa;
        }

        // Mostrar modal de selección
        if (!mounted) return;
        final resultado = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => ModalSeleccionarModoCobro(
            mesaActual: mesaNombre,
            totalMesaActual: totalGeneral,
            mesasRelacionadas: mesasRelacionadas,
            totalesPorMesa: totalesPorMesa,
            totalUnificado: totalUnificado,
          ),
        );

        if (resultado == null) return; // Usuario canceló

        cobroUnificado = resultado['unificado'] == true;
        if (cobroUnificado) {
          mesasACobrar = [mesaId, ...mesasRelacionadas.map((m) => m['id'] as String)];
          // Usar el total unificado para el modal de pago
          if (!mounted) return;
          final Map<String, dynamic>? pagoResultUnif = await showDialog(
            context: context,
            builder: (ctx) => ModalProcesarPago(
              totalAPagar: totalUnificado,
              placeId: placeId,
            ),
          );

          if (pagoResultUnif == null || (pagoResultUnif['pagos'] as List).isEmpty) return;

          final List<Map<String, dynamic>> resultadoPagosUnif =
              List<Map<String, dynamic>>.from(pagoResultUnif['pagos'] as List);
          final double totalFinalUnif =
              (pagoResultUnif['totalFinal'] as num?)?.toDouble() ?? totalUnificado;
          final double descuentoUnif =
              (pagoResultUnif['descuentoAplicado'] as num?)?.toDouble() ?? 0.0;
          final String? codigoUnif = pagoResultUnif['codigoAplicado'] as String?;

          if (!mounted) return;
          await _cobrarCuentasUnificadas(
            mesasACobrar,
            totalFinalUnif,
            resultadoPagosUnif,
            descuento: descuentoUnif,
            codigoDescuento: codigoUnif,
          );
          return;
        }
      }

      // Cobro individual (comportamiento original)
      if (!mounted) return;
      final Map<String, dynamic>? pagoResult = await showDialog(
        context: context,
        builder: (ctx) => ModalProcesarPago(
          totalAPagar: totalGeneral,
          placeId: placeId,
        ),
      );

      if (pagoResult == null || (pagoResult['pagos'] as List).isEmpty) return;

      final List<Map<String, dynamic>> resultadoPagos =
          List<Map<String, dynamic>>.from(pagoResult['pagos'] as List);
      final double totalFinal =
          (pagoResult['totalFinal'] as num?)?.toDouble() ?? totalGeneral;
      final double descuento =
          (pagoResult['descuentoAplicado'] as num?)?.toDouble() ?? 0.0;
      final String? codigoDescuento = pagoResult['codigoAplicado'] as String?;

      if (!mounted) return;
      await _cobrarCuentaIndividual(
        totalFinal,
        resultadoPagos,
        descuento: descuento,
        codigoDescuento: codigoDescuento,
      );
    } catch (e) {
      debugPrint("Error cobrando: $e");
      if (!mounted) return;
      setState(() => setGuardando(false));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al cobrar"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Cobra una cuenta individual (comportamiento original)
  Future<void> _cobrarCuentaIndividual(
    double totalGeneral,
    List<Map<String, dynamic>> resultadoPagos, {
    double descuento = 0,
    String? codigoDescuento,
  }) async {
    setState(() => setGuardando(true));

    try {
      final batch = FirebaseFirestore.instance.batch();

      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId)
          .collection('cuenta_items')
          .get();

      List<Map<String, dynamic>> itemsVendidos = [];
      for (var doc in itemsSnapshot.docs) {
        itemsVendidos.add(doc.data());
        batch.delete(doc.reference);
      }

      final ventaRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .doc();

      double totalEfectivo = 0;
      for (var p in resultadoPagos) {
        if (p['metodo'] == 'efectivo') {
          totalEfectivo += PosUtils.safeDouble(p['monto']);
        }
      }

      batch.set(ventaRef, {
        'total': totalGeneral,
        'fecha': FieldValue.serverTimestamp(),
        'mesa': mesaNombre,
        'mesaId': mesaId,
        'items': itemsVendidos,
        'origen': 'salon',
        'pagos': resultadoPagos,
        'totalEfectivo': totalEfectivo,
        'totalDigital': totalGeneral - totalEfectivo,
        'metodoPrincipal': resultadoPagos.length > 1
            ? 'mixto'
            : resultadoPagos.first['metodo'],
        if (descuento > 0) 'descuentoAplicado': descuento,
        if (codigoDescuento != null && codigoDescuento.isNotEmpty)
          'codigoDescuento': codigoDescuento,
      });

      final mesaRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId);
      
      // Obtener datos de la mesa para verificar si tiene reserva activa
      final mesaSnap = await mesaRef.get();
      final mesaData = mesaSnap.data();
      final reservaIdActiva = mesaData?['reservaIdActiva'] as String?;
      
      // Si la mesa tiene una reserva activa, marcarla como completada
      if (reservaIdActiva != null && reservaIdActiva.isNotEmpty) {
        // Buscar la reserva directamente en el placeId actual
        final reservaRef = FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('reservas')
            .doc(reservaIdActiva);
        
        final reservaSnap = await reservaRef.get();
        if (reservaSnap.exists) {
          final reservaData = reservaSnap.data();
          final estadoReserva = reservaData?['estado'] as String?;
          
          // Solo actualizar si está en un estado que puede completarse
          if (estadoReserva == 'en_curso' || estadoReserva == 'confirmada') {
            batch.update(reservaRef, {
              'estado': 'completada',
            });
          }
        }
        
        // Marcar mesa como pagada pero NO liberarla (mantener reservaIdActiva y clienteActivo)
        // La mesa se liberará manualmente cuando el cliente se retire
        batch.update(mesaRef, {
          'estado': 'pagada',
          // Mantenemos clienteActivo y reservaIdActiva para que el mozo pueda liberar manualmente
        });
      } else {
        // Si no hay reserva activa, marcar como pagada pero mantener clienteActivo
        batch.update(mesaRef, {
          'estado': 'pagada',
          // Mantenemos clienteActivo para que el mozo pueda liberar manualmente
        });
      }

      await batch.commit();

      if (!mounted) return;
      setState(() {
        setPedidoNuevo([]);
        setGuardando(false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cobro registrado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error cobrando cuenta individual: $e");
      if (!mounted) return;
      setState(() => setGuardando(false));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al cobrar"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Cobra múltiples cuentas unificadas en una sola venta
  Future<void> _cobrarCuentasUnificadas(
    List<String> mesasIds,
    double totalUnificado,
    List<Map<String, dynamic>> resultadoPagos, {
    double descuento = 0,
    String? codigoDescuento,
  }) async {
    setState(() => setGuardando(true));

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Obtener items de todas las mesas
      List<Map<String, dynamic>> itemsVendidos = [];
      List<String> nombresMesas = [];

      for (final mesaIdCobro in mesasIds) {
        final mesaRef = FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('mesas')
            .doc(mesaIdCobro);
        
        final mesaSnap = await mesaRef.get();
        final mesaData = mesaSnap.data();
        nombresMesas.add(mesaData?['nombre'] ?? 'Mesa');
        final reservaIdActiva = mesaData?['reservaIdActiva'] as String?;

        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('mesas')
            .doc(mesaIdCobro)
            .collection('cuenta_items')
            .get();

        for (var doc in itemsSnapshot.docs) {
          final itemData = doc.data();
          // Agregar información de la mesa de origen al item
          itemsVendidos.add({
            ...itemData,
            'mesaOrigen': mesaData?['nombre'] ?? 'Mesa',
            'mesaIdOrigen': mesaIdCobro,
          });
          batch.delete(doc.reference);
        }
        
        // Si la mesa tiene una reserva activa, marcarla como completada
        if (reservaIdActiva != null && reservaIdActiva.isNotEmpty) {
          // Buscar la reserva directamente en el placeId actual
          final reservaRef = FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .collection('reservas')
              .doc(reservaIdActiva);
          
          final reservaSnap = await reservaRef.get();
          if (reservaSnap.exists) {
            final reservaData = reservaSnap.data();
            final estadoReserva = reservaData?['estado'] as String?;
            
            // Solo actualizar si está en un estado que puede completarse
            if (estadoReserva == 'en_curso' || estadoReserva == 'confirmada') {
              batch.update(reservaRef, {
                'estado': 'completada',
              });
            }
          }
          
          // Marcar mesa como pagada pero NO liberarla (mantener reservaIdActiva y clienteActivo)
          // La mesa se liberará manualmente cuando el cliente se retire
          batch.update(mesaRef, {
            'estado': 'pagada',
            // Mantenemos clienteActivo y reservaIdActiva para que el mozo pueda liberar manualmente
          });
        } else {
          // Si no hay reserva activa, marcar como pagada pero mantener clienteActivo
          batch.update(mesaRef, {
            'estado': 'pagada',
            // Mantenemos clienteActivo para que el mozo pueda liberar manualmente
          });
        }
      }

      // Crear una sola venta unificada
      final ventaRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .doc();

      double totalEfectivo = 0;
      for (var p in resultadoPagos) {
        if (p['metodo'] == 'efectivo') {
          totalEfectivo += PosUtils.safeDouble(p['monto']);
        }
      }

      batch.set(ventaRef, {
        'total': totalUnificado,
        'fecha': FieldValue.serverTimestamp(),
        'mesa': nombresMesas.length == 1 
            ? nombresMesas.first 
            : '${nombresMesas.length} mesas (${nombresMesas.join(", ")})',
        'mesaId': mesasIds.length == 1 ? mesasIds.first : mesasIds,
        'mesaNombre': nombresMesas.length == 1 ? nombresMesas.first : nombresMesas,
        'items': itemsVendidos,
        'origen': 'salon',
        'pagos': resultadoPagos,
        'totalEfectivo': totalEfectivo,
        'totalDigital': totalUnificado - totalEfectivo,
        'metodoPrincipal': resultadoPagos.length > 1
            ? 'mixto'
            : resultadoPagos.first['metodo'],
        'cuentaUnificada': true, // Flag para identificar cuentas unificadas
        if (descuento > 0) 'descuentoAplicado': descuento,
        if (codigoDescuento != null && codigoDescuento.isNotEmpty)
          'codigoDescuento': codigoDescuento,
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        setPedidoNuevo([]);
        setGuardando(false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Cobro unificado registrado (${mesasIds.length} mesa${mesasIds.length > 1 ? 's' : ''})",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error cobrando cuentas unificadas: $e");
      if (!mounted) return;
      setState(() => setGuardando(false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cobrar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Muestra un diálogo de alerta cuando la caja está cerrada
  void _mostrarAlertaCajaCerrada() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("¡CAJA CERRADA!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "No se pueden procesar cobros sin una caja abierta.\nPor favor, pedile al encargado que realice la APERTURA DE TURNO.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendido", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  /// Libera la mesa y la marca como disponible
  /// Solo debe llamarse manualmente cuando el cliente se retira físicamente
  Future<void> liberarMesa() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Liberar Mesa?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Esto pondrá la mesa en verde (LIBRE) y la dejará disponible para nuevas reservas.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("LIBERAR"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Obtener datos actuales de la mesa para verificar si tiene reserva activa
      final mesaSnap = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId)
          .get();

      final mesaData = mesaSnap.data();
      final reservaIdActiva = mesaData?['reservaIdActiva'] as String?;

      final batch = FirebaseFirestore.instance.batch();
      final mesaRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('mesas')
          .doc(mesaId);

      // Si tiene reserva activa, también actualizar el estado de la reserva a completada
      if (reservaIdActiva != null) {
        final reservaRef = FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('reservas')
            .doc(reservaIdActiva);
        
        final reservaSnap = await reservaRef.get();
        if (reservaSnap.exists) {
          final reservaData = reservaSnap.data();
          final estadoReserva = reservaData?['estado'] as String?;
          
          // Solo actualizar si está en un estado que puede completarse
          if (estadoReserva == 'en_curso' || estadoReserva == 'confirmada') {
            batch.update(reservaRef, {
              'estado': 'completada',
            });
          }
        }
      }

      // Liberar la mesa completamente
      batch.update(mesaRef, {
        'estado': 'libre',
        'clienteActivo': FieldValue.delete(),
        'reservaIdActiva': FieldValue.delete(),
        'fechaOcupacion': FieldValue.delete(),
      });

      await batch.commit();

      // Marcar como cancelados los pedidos que estaban en cocina (si había alguno pendiente)
      await MesasLogicMixin.cancelarOrdenesPendientesCocina(
        placeId: placeId,
        mesaId: mesaId,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error liberando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al liberar la mesa"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cancela la suscripción de Firestore para evitar fugas de memoria
  void disposeTomaPedidoLogic() {
    _pedidoSubscription?.cancel();
    _pedidoSubscription = null;
  }
}

/// Modal para seleccionar entre cobro individual o unificado cuando hay mesas relacionadas
class ModalSeleccionarModoCobro extends StatelessWidget {
  final String mesaActual;
  final double totalMesaActual;
  final List<Map<String, dynamic>> mesasRelacionadas;
  final Map<String, double> totalesPorMesa;
  final double totalUnificado;

  const ModalSeleccionarModoCobro({
    super.key,
    required this.mesaActual,
    required this.totalMesaActual,
    required this.mesasRelacionadas,
    required this.totalesPorMesa,
    required this.totalUnificado,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        "Modo de Cobro",
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Esta mesa pertenece a un grupo de reserva. ¿Cómo deseas cobrar?",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Opción 1: Cobro Individual
            InkWell(
              onTap: () => Navigator.pop(context, {'unificado': false}),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        const Text(
                          "Cobro Individual",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Mesa: $mesaActual",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total: \$${NumberFormat("#,##0").format(totalMesaActual)}",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Cobra solo esta mesa. Las otras mesas se cobran por separado.",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Opción 2: Cobro Unificado
            InkWell(
              onTap: () => Navigator.pop(context, {'unificado': true}),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        const Text(
                          "Cobro Unificado",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${mesasRelacionadas.length + 1} mesas: $mesaActual, ${mesasRelacionadas.map((m) => m['nombre']).join(", ")}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total: \$${NumberFormat("#,##0").format(totalUnificado)}",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Suma todas las mesas del grupo en una sola cuenta. Ideal para dividir gastos entre todos.",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    // Desglose por mesa
                    ...mesasRelacionadas.map((mesa) {
                      final totalMesa = totalesPorMesa[mesa['id']] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${mesa['nombre']}:",
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                            Text(
                              "\$${NumberFormat("#,##0").format(totalMesa)}",
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
