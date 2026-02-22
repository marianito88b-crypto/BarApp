import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/sections/reservas_mobile.dart';

/// Tarjeta detallada de reservas del día.
class ReservasHoyDetailedCard extends StatelessWidget {
  final String placeId;
  final bool isDesktop;
  final Function(String tabName)? onNavigateToTab;

  const ReservasHoyDetailedCard({
    super.key,
    required this.placeId,
    this.isDesktop = false,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    const int horaCorte = 6;
    final now = DateTime.now();
    DateTime fechaNegocio =
        now.hour < horaCorte ? now.subtract(const Duration(days: 1)) : now;
    final start = DateTime(
      fechaNegocio.year,
      fechaNegocio.month,
      fechaNegocio.day,
      horaCorte,
      0,
      0,
    );
    final end = start.add(const Duration(hours: 24));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("places")
          .doc(placeId)
          .collection("reservas")
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('fecha', isLessThan: Timestamp.fromDate(end))
          .snapshots(),
      builder: (context, snap) {
        int pendientes = 0;
        int confirmadas = 0;
        int completadas = 0;

        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            final estado =
                (doc.data() as Map<String, dynamic>)['estado'] ?? 'pendiente';
            if (estado == 'pendiente') {
              pendientes++;
            } else if (estado == 'confirmada') {
              confirmadas++;
            } else if (estado == 'completada' || estado == 'finalizada') {
              // Incluimos tanto completada como finalizada en "completadas"
              completadas++;
            }
            // Nota: 'en_curso' no se cuenta aquí porque si la reserva está en curso,
            // debería tener mesa ocupada, pero al cobrar pasa a 'completada'
          }
        }

        Widget content = Container(
          height: isDesktop ? 140 : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Colors.purpleAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Reservas Hoy",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              if (!isDesktop) const SizedBox(height: 10),
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ReservaCounter(
                      label: "Confirmadas",
                      count: confirmadas,
                      color: Colors.blueAccent,
                      isBold: true,
                    ),
                    _ReservaCounter(
                      label: "Pendientes",
                      count: pendientes,
                      color: Colors.orangeAccent,
                    ),
                    _ReservaCounter(
                      label: "Completadas",
                      count: completadas,
                      color: Colors.greenAccent,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _ReservaRowMobile(
                      label: "Confirmadas",
                      count: confirmadas,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 4),
                    _ReservaRowMobile(
                      label: "Pendientes",
                      count: pendientes,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 4),
                    _ReservaRowMobile(
                      label: "Completadas",
                      count: completadas,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
            ],
          ),
        );

        return InkWell(
          onTap: () {
            if (onNavigateToTab != null) {
              onNavigateToTab!('Reservas');
            } else {
              // Fallback: navegación tradicional si no hay callback
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReservasMobile(placeId: placeId),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: content,
        );
      },
    );
  }
}

class _ReservaCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isBold;

  const _ReservaCounter({
    required this.label,
    required this.count,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            color: color,
            fontSize: isBold ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }
}

class _ReservaRowMobile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ReservaRowMobile({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Text(
          "$count",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
