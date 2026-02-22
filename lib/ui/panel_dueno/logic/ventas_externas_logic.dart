import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barapp/services/ventas_externas/ventas_externas_service.dart';

/// Mixin que contiene la lógica de negocio para el carrito de ventas externas
///
/// Requiere que la clase que lo use implemente:
/// - Método: setState (de State)
mixin VentaExternaCartMixin<T extends StatefulWidget> on State<T> {
  // 🛒 Pedido en memoria
  final List<Map<String, dynamic>> cart = [];

  /// Calcula el total del carrito
  double get cartTotal =>
      cart.fold(0.0, (acc, item) => acc + (item['precio'] * item['cantidad']));

  /// Agrega un producto al carrito o incrementa su cantidad si ya existe
  void agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      final index = cart.indexWhere((p) => p['id'] == producto['id']);
      if (index != -1) {
        cart[index]['cantidad']++;
      } else {
        cart.add({
          'id': producto['id'],
          'nombre': producto['nombre'],
          'precio': producto['precio'],
          'cantidad': 1,
        });
      }
    });
  }

  /// Resta un producto del carrito o lo elimina si la cantidad llega a 0
  void restarProducto(int index) {
    setState(() {
      if (cart[index]['cantidad'] > 1) {
        cart[index]['cantidad']--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  /// Limpia el carrito completamente
  void limpiarCarrito() {
    setState(() {
      cart.clear();
    });
  }

  /// Limpia el carrito sin llamar a setState (útil cuando ya estás dentro de un setState)
  void limpiarCarritoSinSetState() {
    cart.clear();
  }
}

/// Mixin que contiene la lógica de negocio para el checkout de ventas externas
///
/// Requiere que la clase que lo use implemente:
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin VentaExternaCheckoutMixin<T extends StatefulWidget> on State<T> {
  /// Valida que los pagos mixtos sumen correctamente el total
  /// 
  /// [pagoMixto]: Mapa con los montos de efectivo, mercadopago y transferencia
  /// [total]: Total esperado de la venta
  /// 
  /// Retorna true si la suma coincide (con margen de error de 0.5), false en caso contrario.
  bool validarPagoMixto(Map<String, double> pagoMixto, double total) {
    final efectivo = pagoMixto['efectivo'] ?? 0.0;
    final mp = pagoMixto['mercadopago'] ?? 0.0;
    final transf = pagoMixto['transferencia'] ?? 0.0;
    final suma = efectivo + mp + transf;

    return (suma - total).abs() <= 0.5;
  }

  /// Construye la estructura de pagos según el método seleccionado
  /// 
  /// [metodoSeleccionado]: Método de pago seleccionado ('Efectivo', 'MercadoPago', 'Transferencia', 'Mixto')
  /// [pagoMixto]: Mapa con los montos de pago mixto (solo usado si método es 'Mixto')
  /// [total]: Total de la venta
  /// 
  /// Retorna una lista de pagos en formato estándar para Firestore.
  List<Map<String, dynamic>> construirPagos({
    required String metodoSeleccionado,
    required Map<String, double> pagoMixto,
    required double total,
  }) {
    List<Map<String, dynamic>> pagos = [];

    if (metodoSeleccionado == 'Mixto') {
      final efectivo = pagoMixto['efectivo'] ?? 0.0;
      final mp = pagoMixto['mercadopago'] ?? 0.0;
      final transf = pagoMixto['transferencia'] ?? 0.0;

      if (efectivo > 0) {
        pagos.add({'metodo': 'efectivo', 'monto': efectivo});
      }
      if (mp > 0) {
        pagos.add({'metodo': 'mercadopago', 'monto': mp});
      }
      if (transf > 0) {
        pagos.add({'metodo': 'transferencia', 'monto': transf});
      }
    } else {
      // Pago simple
      pagos.add({
        'metodo': metodoSeleccionado.toLowerCase(),
        'monto': total,
      });
    }

    return pagos;
  }

  /// Registra una venta externa con productos usando el servicio estandarizado
  /// 
  /// [placeId]: ID del lugar
  /// [items]: Lista de items del pedido
  /// [pagos]: Lista de pagos en formato estándar
  /// [total]: Total de la venta
  /// [canal]: Canal de venta seleccionado
  /// [canalCustom]: Canal personalizado si se seleccionó 'Otro'
  /// [nota]: Nota opcional para ventas rápidas
  /// 
  /// Retorna true si se registró exitosamente, false en caso contrario.
  /// Maneja errores de conexión y otros errores de Firebase de forma robusta.
  Future<bool> registrarVentaConProductos({
    required String placeId,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> pagos,
    required double total,
    required String canal,
    String? canalCustom,
    String? nota,
  }) async {
    try {
      await VentasExternasService.registrarVentaConProductos(
        placeId: placeId,
        items: items,
        pagos: pagos,
        total: total,
        canal: canal,
        canalCustom: canalCustom,
        nota: nota,
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint("❌ Error Firebase registrando venta externa: ${e.code} - ${e.message}");
      if (mounted) {
        String mensajeError;
        switch (e.code) {
          case 'unavailable':
          case 'deadline-exceeded':
            mensajeError = "⚠️ Sin conexión. Verifica tu internet e intenta nuevamente.";
            break;
          case 'permission-denied':
            mensajeError = "❌ No tienes permisos para realizar esta acción.";
            break;
          default:
            mensajeError = "❌ Error al guardar: ${e.message ?? 'Error desconocido'}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error inesperado registrando venta externa: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error inesperado: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  /// Valida y registra una venta externa con validación de pagos mixtos
  /// 
  /// Este método combina la validación de pagos mixtos con el registro de la venta.
  /// 
  /// [placeId]: ID del lugar
  /// [items]: Lista de items del pedido
  /// [total]: Total de la venta
  /// [metodoSeleccionado]: Método de pago seleccionado
  /// [pagoMixto]: Mapa con los montos de pago mixto
  /// [canal]: Canal de venta seleccionado
  /// [canalCustom]: Canal personalizado si se seleccionó 'Otro'
  /// [nota]: Nota opcional para ventas rápidas
  /// 
  /// Retorna true si se registró exitosamente, false en caso contrario.
  Future<bool> validarYRegistrarVenta({
    required String placeId,
    required List<Map<String, dynamic>> items,
    required double total,
    required String metodoSeleccionado,
    required Map<String, double> pagoMixto,
    required String canal,
    String? canalCustom,
    String? nota,
  }) async {
    // Validar pago mixto si aplica
    if (metodoSeleccionado == 'Mixto') {
      if (!validarPagoMixto(pagoMixto, total)) {
        final efectivo = pagoMixto['efectivo'] ?? 0.0;
        final mp = pagoMixto['mercadopago'] ?? 0.0;
        final transf = pagoMixto['transferencia'] ?? 0.0;
        final suma = efectivo + mp + transf;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ La suma ($efectivo+$mp+$transf = \$$suma) no coincide con el total \$$total",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }
    }

    // Construir pagos
    final pagos = construirPagos(
      metodoSeleccionado: metodoSeleccionado,
      pagoMixto: pagoMixto,
      total: total,
    );

    // Registrar venta
    return await registrarVentaConProductos(
      placeId: placeId,
      items: items,
      pagos: pagos,
      total: total,
      canal: canal,
      canalCustom: canalCustom,
      nota: nota,
    );
  }
}
