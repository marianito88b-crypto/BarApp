import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'delivery_badge.dart';
import 'client_stars_indicator.dart';
import 'client_rating_dialog.dart';
import '../../logic/delivery_logic.dart';

/// Tarjeta unificada e inteligente para mostrar pedidos de delivery
/// 
/// Muestra botones según el userRol (admin vs repartidor) y el estado del pedido.
/// Unifica la lógica de _DetailedOrderCard y _OrderCard.
class OrderDeliveryCard extends StatefulWidget {
  final String placeId;
  final String docId;
  final Map<String, dynamic> data;
  final List<QueryDocumentSnapshot> availableDrivers;
  final String userRol; // 'admin' o 'repartidor'
  final bool isDetailed; // true para vista detallada (delivery_mobile), false para compacta (delivery_orders_screen)

  const OrderDeliveryCard({
    super.key,
    required this.placeId,
    required this.docId,
    required this.data,
    required this.availableDrivers,
    required this.userRol,
    this.isDetailed = true,
  });

  @override
  State<OrderDeliveryCard> createState() => _OrderDeliveryCardState();
}

class _OrderDeliveryCardState extends State<OrderDeliveryCard>
    with DeliveryLogicMixin {
  @override
  String get placeId => widget.placeId;

  bool get _isAdmin => widget.userRol != 'repartidor';

  @override
  Widget build(BuildContext context) {
    final status = widget.data['estado'] ?? 'pendiente';
    final items = (widget.data['items'] as List?) ?? [];
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0.0;
    final clienteNombre = widget.data['clienteNombre'] ?? 'Cliente';
    final clienteTel = widget.data['clienteTelefono'] ?? '';
    final direccion = widget.data['direccion'] ?? 'Retiro en Local';
    final metodoEntrega = widget.data['metodoEntrega'] ?? 'retiro';
    final driverName = widget.data['driverName'];
    final metodoPago = widget.data['metodoPago'] ?? 'efectivo';
    final timestamp = (widget.data['createdAt'] as Timestamp?)?.toDate();
    final hora = timestamp != null ? DateFormat('HH:mm').format(timestamp) : '--:--';

    // Obtener color del badge para el borde
    final badgeInfo = DeliveryBadge.getStatusInfo(status);
    final statusColor = badgeInfo.color;

    // Determinar color de fondo según estado (solo para vista compacta)
    Color cardColor = const Color(0xFF1E1E1E);
    if (!widget.isDetailed) {
      switch (status) {
        case 'pendiente':
          cardColor = const Color(0xFF2A1C10);
          break;
        case 'confirmado':
          cardColor = const Color(0xFF1C2A10);
          break;
        default:
          cardColor = const Color(0xFF1E1E1E);
      }
    }

    return Card(
      color: cardColor,
      elevation: widget.isDetailed ? 0 : 4,
      margin: widget.isDetailed ? EdgeInsets.zero : EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: widget.isDetailed ? 0.2 : 0.3),
          width: widget.isDetailed ? 1 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER con Badge y acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DeliveryBadge(status: status),
                Row(
                  children: [
                    if (!widget.isDetailed) ...[
                      Icon(
                        metodoEntrega == 'retiro' ? Icons.store : Icons.motorcycle,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hora,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (clienteTel.toString().isNotEmpty)
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                          size: 20,
                        ),
                        onPressed: () => openWhatsAppTicket(
                              phone: clienteTel,
                              orderData: widget.data,
                            ),
                        tooltip: widget.isDetailed
                            ? null
                            : "Enviar Ticket por WhatsApp",
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: widget.isDetailed ? 12 : 16),

            // DATOS CLIENTE
            if (widget.isDetailed) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clienteNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (widget.data['userId'] != null)
                    ClientStarsIndicator(
                      userId: widget.data['userId'].toString(),
                    ),
                ],
              ),
              Text(
                metodoEntrega == 'retiro'
                    ? "Retira en Local"
                    : direccion,
                style: const TextStyle(color: Colors.white70),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                clienteNombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (widget.data['userId'] != null)
                              ClientStarsIndicator(
                                userId: widget.data['userId'].toString(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metodoEntrega == 'retiro'
                              ? "Retira en el Local"
                              : direccion,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: metodoEntrega == 'retiro'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (driverName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.sports_motorsports,
                                  size: 12,
                                  color: Colors.purpleAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Chofer: $driverName",
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            Divider(color: Colors.white10, height: widget.isDetailed ? 32 : 24),

            // ITEMS
            ...items.map<Widget>((item) {
              final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
              final nombre = item['nombre'] ?? 'Sin Nombre';
              final precio = (item['precio'] as num?)?.toDouble() ?? 0.0;

              if (widget.isDetailed) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• ${cantidad}x $nombre",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${cantidad}x ",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Text(
                        "\$${(precio * cantidad).toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                );
              }
            }),

            // NOTAS (solo en vista compacta)
            if (!widget.isDetailed &&
                widget.data['notas'] != null &&
                widget.data['notas'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Nota: ${widget.data['notas']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: widget.isDetailed ? 16 : 20),

            // TOTAL Y PAGO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${NumberFormat("#,##0", "es_AR").format(total)}",
                  style: TextStyle(
                    color: widget.isDetailed ? Colors.greenAccent : Colors.white,
                    fontSize: widget.isDetailed ? 20 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!widget.isDetailed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          metodoPago.toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: widget.isDetailed ? 16 : 20),

            // BOTONES DE ACCIÓN
            if (!['entregado', 'rechazado', 'error'].contains(status))
              _buildActionButtons(status, metodoEntrega),
            
            // Botón para calificar cliente (solo pedidos entregados)
            if (status == 'entregado' && _isAdmin)
              _buildRateClientButton(),
            
            // Error de stock (solo en vista compacta)
            if (!widget.isDetailed &&
                status == 'error' &&
                widget.data['errorStock'] != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.2),
                child: Text(
                  "Error Stock: ${widget.data['errorStock']}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status, String metodoEntrega) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. PENDIENTE / CONFIRMADO -> A COCINA (solo admin)
    if (status == 'pendiente' || status == 'confirmado') {
      if (!_isAdmin) {
        return const Text(
          "Esperando confirmación...",
          style: TextStyle(color: Colors.white24),
        );
      }

      // Vista detallada: solo botón simple
      if (widget.isDetailed) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => mandarACocina(
                  orderId: widget.docId,
                  orderData: widget.data,
                ),
            child: const Text("MANDAR A COCINA"),
          ),
        );
      }

      // Vista compacta: botones con impresión
      return Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
            icon: const Icon(Icons.print, color: Colors.white70),
            tooltip: "Imprimir Comanda Cocina",
            onPressed: () => printComanda(widget.data),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => updateStatus(widget.docId, 'rechazado'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text("Rechazar"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    status == 'confirmado' ? Colors.green : Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => acceptOrder(
                    orderId: widget.docId,
                    metodoEntrega: metodoEntrega,
                    orderData: widget.data,
                  ),
              icon: const Icon(Icons.soup_kitchen),
              label: Text(status == 'confirmado' ? "Cocinar" : "A Cocina"),
            ),
          ),
        ],
      );
    }

    // 2. EN PREPARACION -> LISTO
    if (status == 'en_preparacion') {
      if (widget.isDetailed) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              "👨‍🍳 EL PEDIDO SE ESTÁ PREPARANDO",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Cocinando...",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => markAsPrepared(
                    orderId: widget.docId,
                    metodoEntrega: metodoEntrega,
                    orderData: widget.data,
                  ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text("LISTO", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // 3. PREPARADO -> ASIGNAR CHOFER (solo admin, solo delivery)
    if (status == 'preparado') {
      if (!_isAdmin) {
        return const Text(
          "Esperando que te lo asignen...",
          style: TextStyle(color: Colors.white24),
        );
      }

      if (widget.isDetailed) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () => _showAssignDriverDialog(context),
            child: const Text("ASIGNAR CHOFER AHORA"),
          ),
        );
      }

      return Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
            icon: const Icon(Icons.receipt, color: Colors.white),
            tooltip: "Imprimir Ticket Cliente",
            onPressed: () => printCliente(widget.data),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showAssignDriverDialog(context),
              icon: const Icon(Icons.motorcycle),
              label: const Text("ASIGNAR CHOFER"),
            ),
          ),
        ],
      );
    }

    // 4. EN CAMINO / RETIRO -> FINALIZAR
    if (status == 'en_camino' || status == 'listo_para_retirar') {
      final bool isDelivery = status == 'en_camino';
      
      if (widget.isDetailed) {
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.white54),
              onPressed: () => _mostrarTicket(context, widget.data),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => finalizeAndMoveToSales(
                      orderId: widget.docId,
                      orderData: widget.data,
                    ),
                child: const Text("ENTREGADO / COBRADO"),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
            icon: const Icon(Icons.receipt, color: Colors.white),
            onPressed: () => printCliente(widget.data),
            tooltip: "Imprimir Ticket",
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle),
              label: Text(
                isDelivery ? "ENTREGA CONFIRMADA" : "ENTREGADO EN MANO",
              ),
              onPressed: () => finalizeAndMoveToSales(
                    orderId: widget.docId,
                    orderData: widget.data,
                  ),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  /// Botón para calificar al cliente (solo para pedidos entregados)
  Widget _buildRateClientButton() {
    final userId = widget.data['userId'] as String?;
    final ratingCliente = widget.data['rating_cliente'] as Map<String, dynamic>?;
    
    // Solo mostrar si hay userId y no tiene calificación aún
    if (userId == null || userId.isEmpty || ratingCliente != null) {
      return const SizedBox.shrink();
    }

    final clienteNombre = widget.data['clienteNombre'] ?? 'Cliente';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
          foregroundColor: Colors.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
          ),
        ),
        icon: const Icon(Icons.star_border),
        label: const Text(
          "Calificar Cliente",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ClientRatingDialog(
              userId: userId,
              orderId: widget.docId,
              placeId: widget.placeId,
              clienteNombre: clienteNombre.toString(),
            ),
          );
        },
      ),
    );
  }

  // --- DIÁLOGOS DE UI ---

  /// Muestra el diálogo para asignar un chofer
  void _showAssignDriverDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Seleccionar Chofer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            if (widget.availableDrivers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No hay choferes activos (rol: repartidor)",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ...widget.availableDrivers.map((d) {
              final driverData = d.data() as Map<String, dynamic>;
              final String nombreChofer = driverData['nombre'] ?? 'Sin Nombre';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                  child: const Icon(Icons.motorcycle, color: Colors.orangeAccent),
                ),
                title: Text(nombreChofer, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  driverData['email'] ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                onTap: () async {
                  Navigator.pop(ctx);
                  await assignDriver(
                    orderId: widget.docId,
                    driverDoc: d,
                    orderData: widget.data,
                  );
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarTicket(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "TICKET DE REPARTO",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Divider(color: Colors.black),
            _tRow("CLIENTE:", data['clienteNombre']),
            _tRow("DIRECCIÓN:", data['direccion'], bold: true),
            const Divider(),
            _tRow("A COBRAR:", "\$${data['total']}", bold: true),
          ],
        ),
      ),
    );
  }


  Widget _tRow(String l, String? v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            Text(
              v ?? '-',
              style: TextStyle(
                color: Colors.black,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}
