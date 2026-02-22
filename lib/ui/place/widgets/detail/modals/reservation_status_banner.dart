import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Banner de estado de reserva con opción de cancelación
/// 
/// Muestra el estado de la reserva activa y permite cancelarla con liberación de mesa
class ReservationStatusBanner extends StatelessWidget {
  final String placeId;

  const ReservationStatusBanner({
    super.key,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('reservas')
          .where('userId', isEqualTo: user.uid)
          .where('estado', whereIn: ['pendiente', 'confirmada']) // Solo activas
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Datos de la reserva
        final doc = snapshot.data!.docs.first; // Necesitamos el DOC para el ID
        final data = doc.data() as Map<String, dynamic>;
        final String reservaId = doc.id; // 🔥 ID para cancelar
        
        // Manejar mesaId que puede ser String o List<String>
        final dynamic mesaIdRaw = data['mesaId'];
        List<String>? mesasIds;
        if (mesaIdRaw != null) {
          if (mesaIdRaw is List) {
            mesasIds = List<String>.from(mesaIdRaw);
          } else {
            mesasIds = [mesaIdRaw.toString()];
          }
        }

        final estado = data['estado'] ?? 'pendiente';
        final personas = data['personas'] ?? 2;

        // Configuración visual
        final isConfirmed = estado == 'confirmada';
        final colorBg = isConfirmed
            ? Colors.greenAccent.withValues(alpha: 0.1)
            : Colors.orangeAccent.withValues(alpha: 0.1);
        final colorText = isConfirmed ? Colors.greenAccent : Colors.orangeAccent;
        final icon = isConfirmed ? Icons.check_circle : Icons.access_time_filled;
        final titulo =
            isConfirmed ? "¡Reserva Confirmada!" : "Solicitud Pendiente";

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: colorBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorText.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // PARTE SUPERIOR: INFO
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: colorText, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: TextStyle(
                              color: colorText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mesasIds != null && mesasIds.length > 1
                                ? "${mesasIds.length} mesas para $personas personas"
                                : "Mesa para $personas personas",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 🔥 Recordatorio sutil de tolerancia solo para reservas activas
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Tolerancia: 15 min",
                                style: TextStyle(
                                  color: isConfirmed
                                      ? Colors.greenAccent.withValues(alpha: 0.8)
                                      : Colors.orangeAccent.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 PARTE INFERIOR: ACCIÓN DE CANCELAR
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "¿No podrás asistir?",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    InkWell(
                      // 🔥 PASAMOS LAS MESAS IDS AQUÍ
                      onTap: () => cancelarReservaPropia(
                        context,
                        placeId,
                        reservaId,
                        mesasIds,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 14,
                            color: Colors.redAccent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "CANCELAR RESERVA",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /// 🗑️ LÓGICA ROBUSTA: CANCELAR Y LIBERAR MESA(S)
  /// Hacemos el método público para que pueda ser usado desde UserReservaCard
  static Future<void> cancelarReservaPropia(
    BuildContext context,
    String placeId,
    String reservaId,
    List<String>? mesasIds,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "¿Cancelar reserva?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          mesasIds != null && mesasIds.length > 1
              ? "Si cancelas ahora, liberarás ${mesasIds.length} mesas para otros clientes. ¿Estás seguro?"
              : "Si cancelas ahora, liberarás la mesa para otros clientes. ¿Estás seguro?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No, mantener"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sí, cancelar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 🔥 USAMOS BATCH: O se hace todo junto, o nada. Es más seguro.
      final batch = FirebaseFirestore.instance.batch();

      // 1. Referencia a la Reserva
      final reservaRef = FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('reservas')
          .doc(reservaId);

      // La borramos
      batch.delete(reservaRef);

      // 2. Liberar Mesa(s) - Soporta múltiples mesas
      if (mesasIds != null && mesasIds.isNotEmpty) {
        for (final mesaId in mesasIds) {
          final mesaRef = FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .collection('mesas')
              .doc(mesaId);

          // Verificar que la mesa realmente pertenece a esta reserva antes de liberarla
          final mesaSnap = await mesaRef.get();
          final reservaActiva = mesaSnap.data()?['reservaIdActiva'];
          
          if (reservaActiva == reservaId) {
            // La liberamos y limpiamos sus datos
            batch.update(mesaRef, {
              'estado': 'libre', // Vuelve a verde
              'clienteActivo': FieldValue.delete(), // Borra el nombre
              'reservaIdActiva': FieldValue.delete() // Borra el ID de reserva
            });
          }
        }
      }

      // 3. Ejecutar todo junto
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reserva cancelada y mesa liberada."),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error cancelando: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cancelar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
