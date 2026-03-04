import 'package:flutter/material.dart';
import 'package:barapp/services/barpoints_service.dart';

/// Ícono de medalla en la barra de progreso.
///
/// Cada hito tiene su propio ícono y color (Bronce, Plata, Oro, Diamante).
/// Se muestra apagado si aún no fue alcanzado.
class MedallaHito extends StatelessWidget {
  final int puntos;
  final int descuento;
  final bool alcanzado;

  const MedallaHito({
    super.key,
    required this.puntos,
    required this.descuento,
    required this.alcanzado,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (puntos) {
      100 => (Icons.military_tech, const Color(0xFFCD7F32)), // Bronce
      250 => (Icons.military_tech, const Color(0xFFC0C0C0)), // Plata
      400 => (Icons.military_tech, const Color(0xFFFFD700)), // Oro
      500 => (Icons.diamond, const Color(0xFF4DD0E1)),        // Diamante
      _ => (Icons.star, Colors.orangeAccent),
    };
    return Tooltip(
      message: '$puntos pts → $descuento%',
      child: Icon(
        icon,
        size: 22,
        color: alcanzado ? color : Colors.white.withValues(alpha: 0.25),
      ),
    );
  }

  /// Devuelve el color asignado a cada nivel (para testing).
  static Color colorParaNivel(int puntos) {
    return switch (puntos) {
      100 => const Color(0xFFCD7F32),
      250 => const Color(0xFFC0C0C0),
      400 => const Color(0xFFFFD700),
      500 => const Color(0xFF4DD0E1),
      _ => Colors.orangeAccent,
    };
  }

  /// Devuelve los niveles definidos en [BarPointsService.nivelesCanje].
  static List<int> get nivelesOrdenados =>
      BarPointsService.nivelesCanje.keys.toList()..sort();
}
