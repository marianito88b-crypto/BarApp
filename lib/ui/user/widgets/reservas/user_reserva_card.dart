import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../panel_dueno/widgets/reservas/reserva_estado_badge.dart';
import '../../../place/widgets/detail/modals/reservation_status_banner.dart';

/// Widget que representa una tarjeta de reserva para el usuario cliente
class UserReservaCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final String placeId;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const UserReservaCard({
    super.key,
    required this.id,
    required this.data,
    required this.placeId,
    this.onCancel,
    this.onEdit,
  });

  String _obtenerTextoMesas(Map<String, dynamic> data) {
    final mesaNombre = data['mesaNombre'];
    final mesaId = data['mesaId'];
    final estado = data['estado'] ?? 'pendiente';
    
    if (mesaId == null || mesaNombre == null) {
      return estado == 'pendiente' 
          ? "Pendiente de asignación de mesas" 
          : "Sin mesa asignada";
    }
    
    if (mesaNombre is List) {
      final nombres = List<String>.from(mesaNombre);
      if (nombres.isEmpty) return "Sin asignar";
      if (nombres.length == 1) return "Mesa: ${nombres.first}";
      return "${nombres.length} mesas: ${nombres.join(', ')}";
    }
    
    return "Mesa: ${mesaNombre.toString()}";
  }

  List<String>? _obtenerMesasIds(Map<String, dynamic> data) {
    final mesaId = data['mesaId'];
    if (mesaId == null) return null;
    
    if (mesaId is List) {
      return List<String>.from(mesaId);
    }
    
    return [mesaId.toString()];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = (data["fecha"] as Timestamp).toDate();
    final hora = DateFormat("HH:mm").format(fecha);
    final dia = DateFormat("d MMM yyyy").format(fecha);
    final estado = data['estado'] ?? 'pendiente';
    final personas = data['personas'] ?? 2;
    final placeName = data['placeName'] ?? 'Lugar';

    // Determinar si se puede cancelar o editar
    final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';
    final puedeEditar = estado == 'pendiente';

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Fecha/Hora y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          hora,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ReservaEstadoBadge(estado: estado),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // INFO: Lugar y Personas
            Row(
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    placeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  "$personas ${personas == 1 ? 'persona' : 'personas'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.table_restaurant,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _obtenerTextoMesas(data),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            // BOTONES DE ACCIÓN
            if (puedeCancelar || puedeEditar) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (puedeEditar && onEdit != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Editar"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (puedeEditar && onEdit != null && puedeCancelar)
                    const SizedBox(width: 12),
                  if (puedeCancelar)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelarReserva(context),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text("Cancelar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _cancelarReserva(BuildContext context) {
    final mesasIds = _obtenerMesasIds(data);
    ReservationStatusBanner.cancelarReservaPropia(
      context,
      placeId,
      id,
      mesasIds,
    );
  }
}
