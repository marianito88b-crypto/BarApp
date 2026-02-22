import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/widgets/mesas/live_timer_badge.dart';

/// Widget que representa una tarjeta de mesa con su estado y acciones
class MesaCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onEditDesktop;
  final VoidCallback? onDeleteDesktop;
  final int? grupoNumber; // Número del grupo (1, 2, 3...) si hay múltiples reservas activas
  final bool showGrupoBadge; // Si debe mostrarse el badge "GRUPO" (solo si hay 2+ mesas con misma reserva)

  const MesaCard({
    super.key,
    required this.data,
    required this.isDesktop,
    required this.onTap,
    required this.onLongPress,
    this.onEditDesktop,
    this.onDeleteDesktop,
    this.grupoNumber,
    this.showGrupoBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final estado = data['estado'] ?? 'libre';
    final String? cliente = data['clienteActivo'];
    final Timestamp? fechaOcupacion = data['fechaOcupacion'];
    final String? reservaIdActiva = data['reservaIdActiva'];

    Color color;
    switch (estado) {
      case 'ocupada':
        color = Colors.redAccent;
        break;
      case 'pagada':
        color = Colors.blueAccent;
        break;
      case 'reservada':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.greenAccent;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(alpha: isDesktop ? 0.3 : 0.5), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['nombre'] ?? '?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if ((estado == 'ocupada' ||
                          estado == 'reservada' ||
                          estado == 'pagada') &&
                      cliente != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(cliente,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    )
                  else
                    Text("${data['capacidad']} personas",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),

            // Badge Estado
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(14))),
                child: Text(estado.toString().toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),

            // Timer dinámico
            if ((estado == 'ocupada' || estado == 'pagada') &&
                fechaOcupacion != null)
              Positioned(
                left: 8,
                top: 8,
                child: LiveTimerBadge(
                    inicio: fechaOcupacion, isPagada: estado == 'pagada'),
              ),

            // Indicador de grupo (solo si hay 2+ mesas con la misma reserva)
            // Si hay múltiples reservas activas, mostrar "Grupo 1", "Grupo 2", etc.
            if (reservaIdActiva != null && 
                (estado == 'ocupada' || estado == 'reservada') &&
                showGrupoBadge)
              Positioned(
                right: isDesktop ? 40 : 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group, color: Colors.purpleAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        grupoNumber != null ? "Grupo $grupoNumber" : "GRUPO",
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (isDesktop)
              Positioned(
                right: 6,
                top: 6,
                child: Row(
                  children: [
                    _MiniButton(
                        icon: Icons.edit,
                        color: Colors.white70,
                        onTap: onEditDesktop),
                    _MiniButton(
                        icon: Icons.delete,
                        color: Colors.redAccent,
                        onTap: onDeleteDesktop),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

/// Botón auxiliar pequeño para acciones de escritorio
class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MiniButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        constraints: const BoxConstraints());
  }
}
