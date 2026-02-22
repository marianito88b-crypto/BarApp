import 'package:flutter/material.dart';
import 'package:barapp/utils/venue_utils.dart';

/// Tarjeta de horarios del lugar
/// 
/// Muestra horarios de apertura/cierre
class SocialHoursCard extends StatelessWidget {
  final Map<String, dynamic> placeData;

  const SocialHoursCard({
    super.key,
    required this.placeData,
  });

  @override
  Widget build(BuildContext context) {
    final String open = placeData['horarioApertura'] ?? '';
    final String close = placeData['horarioCierre'] ?? '';

    // Verificar si está abierto usando VenueUtils
    final bool isOpen = VenueUtils.isVenueOpen(placeData);
    final String formattedHours = VenueUtils.getFormattedHours(placeData);

    // Si no hay horarios configurados, no mostrar nada
    if (open.isEmpty && close.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOpen
                  ? Colors.greenAccent.withValues(alpha: 0.1)
                  : Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 20,
              color: isOpen ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? "ABIERTO AHORA" : "CERRADO",
                  style: TextStyle(
                    color: isOpen ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedHours.isNotEmpty
                      ? formattedHours
                      : "$open - $close",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
