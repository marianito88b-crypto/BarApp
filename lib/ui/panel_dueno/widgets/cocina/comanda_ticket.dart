import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'kitchen_time_badge.dart';

/// Widget que representa un ticket de comanda en el monitor de cocina
/// 
/// Muestra la información de la comanda con:
/// - ID corto formateado (últimos 4 caracteres)
/// - Identificador (mesa o cliente)
/// - Método de entrega
/// - Lista de items con cantidades y notas
/// - Badge de tiempo con color según demora
/// - Botón de despacho
class ComandaTicket extends StatelessWidget {
  final DocumentSnapshot doc;
  final String placeId;

  const ComandaTicket({
    super.key,
    required this.doc,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    
    // Soporte para ambos nombres de timestamp
    final Timestamp? ts = data['createdAt'] ?? data['timestamp'];
    final DateTime fecha = ts != null ? ts.toDate() : DateTime.now();
    
    final colorBorde = _getColorPorTiempo(fecha);

    // 🔥 CORRECCIÓN AQUÍ: PRIORIZAMOS LA MESA
    // Si viene de una mesa, usamos 'mesaNombre'. Si es Delivery, usamos 'clienteNombre'.
    final String identificador = data['mesaNombre'] ?? data['clienteNombre'] ?? 'Anónimo';
    
    // Si viene 'metodoEntrega' lo usamos, si no, intentamos sacar el 'canal' (salon, whatsapp)
    final String metodo = (data['metodoEntrega'] ?? data['canal'] ?? 'MESA').toString().toUpperCase();
    
    final String fullId = doc.id;
    final String shortId = fullId.length >= 4 
        ? fullId.substring(fullId.length - 4).toUpperCase() 
        : fullId.toUpperCase();

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBorde, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorBorde.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24)
                      ),
                      child: Text(
                        "$metodo #$shortId", 
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    KitchenTimeBadge(fecha: fecha),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Cambiamos ícono si es mesa o delivery
                    Icon(
                      metodo.contains('SALON') || metodo.contains('MESA') ? Icons.table_restaurant : Icons.person, 
                      color: Colors.white70, 
                      size: 18
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        identificador.toUpperCase(), // 🔥 Ahora muestra "MESA 1"
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18, 
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (data['notas'] != null && data['notas'].toString().trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.redAccent.withValues(alpha: 0.2), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "NOTA: ${data['notas'].toString().toUpperCase()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. LISTA DE ITEMS
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 12),
              itemBuilder: (_, i) {
                final item = items[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item['cantidad']}x",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nombre'] ?? 'Item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item['nota'] != null && item['nota'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "⚠️ ${item['nota'].toString().toUpperCase()}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. FOOTER
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
            child: InkWell(
              onTap: () => _despacharConSeguridad(context, data),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Container(
                height: 55,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text(
                      "DESPACHAR",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Despacha una comanda con seguridad usando batch de Firestore
  /// 
  /// Determina el nuevo estado según el método de entrega:
  /// - delivery -> 'preparado'
  /// - retiro/takeaway -> 'listo_para_retirar'
  /// - mesa/salon -> 'listo'
  Future<void> _despacharConSeguridad(BuildContext context, Map<String, dynamic> data) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Usamos doc.id directamente porque estamos dentro del widget ComandaTicket
      final orderRef = firestore
          .collection("places")
          .doc(placeId)
          .collection("orders")
          .doc(doc.id); 

      final String metodo = data['metodoEntrega'] ?? data['tipo'] ?? 'mesa';
      String nuevoEstado;

      if (metodo == 'delivery') {
        nuevoEstado = 'preparado'; 
      } else if (metodo == 'retiro' || metodo == 'takeaway') {
        nuevoEstado = 'listo_para_retirar'; 
      } else {
        nuevoEstado = 'listo'; 
      }

      batch.update(orderRef, {
        'estado': nuevoEstado,
        'cocinaDespachadoAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pedido despachado"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("🔥 ERROR DESPACHANDO: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Error al despachar"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Obtiene el color del borde según el tiempo transcurrido desde la creación
  /// 
  /// - Más de 25 minutos: Rojo
  /// - Más de 15 minutos: Naranja
  /// - Menos de 15 minutos: Gris
  Color _getColorPorTiempo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha).inMinutes;
    if (diff > 25) return Colors.redAccent;
    if (diff > 15) return Colors.orangeAccent;
    return Colors.grey;
  }
}
