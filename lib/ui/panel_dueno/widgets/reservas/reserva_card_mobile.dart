import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../user/user_profile_screen.dart';
import 'reserva_estado_badge.dart';

/// Widget que representa una tarjeta de reserva para dispositivos móviles
class ReservaCardMobile extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final String placeId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onUpdateStatus;

  const ReservaCardMobile({
    super.key,
    required this.id,
    required this.data,
    required this.placeId,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStatus,
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
      return "${nombres.length} mesas asignadas";
    }
    
    return "Mesa: ${mesaNombre.toString()}";
  }

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = (data["fecha"] as Timestamp).toDate();
    final hora = DateFormat("HH:mm").format(fecha);
    final dia = DateFormat("d MMM").format(fecha);
    final estado = data['estado'] ?? 'pendiente';

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$dia, $hora hs",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF2C2C2C),
                  onSelected: (v) => v == 'editar' ? onEdit() : onDelete(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Text(
                        "Editar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text(
                        "Eliminar",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    final userId = data['userId'];
                    if (userId != null &&
                        userId is String &&
                        userId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            externalUserId: userId,
                            externalUserName: data['cliente'] ?? 'Usuario',
                            externalUserPhotoUrl: data['userAvatar'],
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: (data['userAvatar'] != null &&
                            data['userAvatar'].isNotEmpty)
                        ? NetworkImage(data['userAvatar'])
                        : null,
                    child: data['userAvatar'] == null
                        ? const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["cliente"] ?? "Cliente",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _obtenerTextoMesas(data),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ReservaEstadoBadge(estado: estado),
              ],
            ),
            const SizedBox(height: 16),

            // BOTONES DE ACCIÓN MÓVIL
            if (estado == 'pendiente' ||
                estado == 'confirmada' ||
                estado == 'en_curso')
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    if (estado == 'pendiente')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onUpdateStatus("rechazada"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Rechazar"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => onUpdateStatus("confirmada"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Confirmar"),
                            ),
                          ),
                        ],
                      ),

                    if (estado == 'confirmada')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => onUpdateStatus("en_curso"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Comenzar / Ocupar Mesa"),
                        ),
                      ),

                    if (estado == 'en_curso')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onUpdateStatus("completada"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text("Finalizar y Liberar Mesa"),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
