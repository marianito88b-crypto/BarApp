import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VentasExternasService {
  
  // REGISTRAR VENTA CON PRODUCTOS (Desde ModalCheckoutVentaExterna)
  static Future<void> registrarVentaConProductos({
    required String placeId,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> pagos,
    required double total,
    required String canal,
    String? canalCustom,
    String? nota,
  }) async {
    final String canalReal = (canal == 'Otro') ? (canalCustom ?? 'Otro') : canal;
    final String metodoPrincipal = _determinarMetodoPrincipal(pagos);
    final batch = FirebaseFirestore.instance.batch();

    // 1. Referencia a la Venta
    final ventaRef = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('ventas')
        .doc();

    // 2. Estructura ESTÁNDAR (La misma que usas en mesas y delivery)
    // GARANTIZAMOS que siempre haya pagos (array) y origen: 'externo'
    final pagosFormateados = pagos.isEmpty
        ? [
            {
              'metodo': 'efectivo',
              'monto': total,
              'fecha': Timestamp.now(),
              'total': total,
            }
          ]
        : pagos.map((p) => {
            ...p,
            'fecha': Timestamp.now(), // Agregamos fecha a cada pago individual
            'total': p['monto'], // Redundancia útil
          }).toList();

    batch.set(ventaRef, {
      'fecha': FieldValue.serverTimestamp(),
      'total': total,

      // Totales discriminados (Asumimos todo comida/producto por ahora en venta externa)
      'totalComida': total,
      'totalEnvio': 0.0,

      // Identificación - SIEMPRE origen: 'externo'
      'mesa': 'Ext: $canalReal', // Para que el Dashboard muestre "Ext: WhatsApp"
      'mesaId': 'EXTERNO', // ID fijo para identificar origen
      'origen': 'externo', // Clave para filtros - SIEMPRE presente
      'canal': canalReal, // Dato extra útil para estadísticas

      // Pagos y Método - SIEMPRE array de pagos
      'metodoPrincipal': metodoPrincipal,
      'pagos': pagosFormateados, // Array siempre presente

      // Items (Limpiamos la data para guardar solo lo necesario)
      'items': items.map((i) => {
        'id': i['id'] ?? 'GENERICO',
        'nombre': i['nombre'],
        'cantidad': i['cantidad'],
        'precio': i['precio'],
        'total': (i['precio'] as num) * (i['cantidad'] as num),
      }).toList(),

      // Nota opcional para ventas rápidas
      if (nota != null && nota.isNotEmpty) 'nota': nota,

      'registradoPor': 'Cajero/Dueño',
    });

    // 3. Descuento de Stock (Solo si son productos reales)
    for (var item in items) {
      if (item['id'] != null && item['id'] != 'GENERICO') {
        final prodRef = FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('menu')
            .doc(item['id']);
        
        // Usamos decremento atómico
        batch.update(prodRef, {
          'stock': FieldValue.increment(-item['cantidad'])
        });
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("❌ Error en batch.commit() de venta externa: $e");
      rethrow; // Re-lanzamos para que el Mixin lo maneje
    }
  }

  // Helper para definir si es "efectivo", "mercadopago" o "mixto"
  static String _determinarMetodoPrincipal(List<Map<String, dynamic>> pagos) {
    if (pagos.length > 1) return 'mixto';
    if (pagos.isEmpty) return 'efectivo'; // Default raro
    return pagos.first['metodo'].toString();
  }
}