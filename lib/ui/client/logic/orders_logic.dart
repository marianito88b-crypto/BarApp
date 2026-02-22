import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mixin que contiene la lógica de negocio para la pantalla de pedidos del cliente
///
/// Requiere que la clase que lo use implemente:
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
mixin ClientOrdersLogicMixin<T extends StatefulWidget> on State<T> {
  /// Obtiene el stream de pedidos filtrado por userId
  /// 
  /// [userId]: ID del usuario autenticado
  /// [active]: Si es true, retorna pedidos en curso. Si es false, retorna historial.
  Stream<QuerySnapshot> getOrdersStream(String userId, bool active) {
    return FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('userId', isEqualTo: userId)
        .where('estado', whereIn: active
            ? [
                'pendiente',
                'confirmado',
                'en_preparacion',
                'preparado',
                'en_camino',
                'listo_para_retirar',
              ]
            : ['entregado', 'rechazado'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Abre WhatsApp con un ticket de texto profesional del pedido
  /// 
  /// [placeId]: ID del lugar
  /// [orderData]: Mapa con todos los datos del pedido
  /// 
  /// Construye un mensaje formateado con:
  /// - Saludo personalizado
  /// - ID del pedido (corto)
  /// - Detalle de items con cantidades y precios
  /// - Costo de envío (si aplica)
  /// - Total formateado
  Future<void> fetchAndOpenWhatsapp(
    String? placeId,
    Map<String, dynamic> orderData,
  ) async {
    if (placeId == null) return;

    final String orderId = orderData['id'] ?? '###';
    final String shortId =
        orderId.length >= 4 ? orderId.substring(0, 4) : orderId;
    final double total = (orderData['total'] as num?)?.toDouble() ?? 0.0;
    final double envio = (orderData['costoEnvio'] as num?)?.toDouble() ?? 0.0;
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
    final String placeName = orderData['placeName'] ?? "El Local";

    try {
      // 1. Buscamos el teléfono del local en Firebase
      final doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();
      final phone = doc.data()?['whatsapp'];

      if (phone != null && phone.toString().isNotEmpty) {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

        // 2. ARMADO DE LA FACTURA / TICKET 🧾
        StringBuffer msg = StringBuffer();
        msg.write("Hola *$placeName*! 👋%0A");
        msg.write(
            "Te envío el comprobante/factura de mi pedido *#$shortId*:%0A%0A");

        // Detalle de Items
        for (var item in items) {
          final cant = item['cantidad'] ?? 1;
          final nombre = item['nombre'] ?? 'Producto';
          final precio = (item['precio'] as num?)?.toDouble() ?? 0.0;
          msg.write(
              "▪️ ${cant}x $nombre (\$${(precio * cant).toStringAsFixed(0)})%0A");
        }

        msg.write("--------------------------------%0A");
        if (envio > 0) {
          msg.write("🛵 Envío: \$${envio.toStringAsFixed(0)}%0A");
        }
        msg.write(
            "💰 *TOTAL: \$${NumberFormat("#,##0", "es_AR").format(total)}*%0A");
        msg.write("--------------------------------%0A");
        msg.write(
            "✅ _Adjunto comprobante de transferencia (si corresponde)_");

        // 3. Lanzar WhatsApp
        final url =
            "https://wa.me/$cleanPhone?text=${msg.toString()}"; // No uses Uri.encodeComponent aquí si usas %0A manuales

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se pudo abrir WhatsApp"),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El local no tiene WhatsApp configurado."),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error abriendo WP: $e");
    }
  }
}
