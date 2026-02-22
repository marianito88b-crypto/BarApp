import 'package:flutter/material.dart';

/// Helper para obtener el color según el rol del staff
Color getColorRol(String? rol) {
  if (rol == 'admin') return Colors.redAccent;
  if (rol == 'cocinero') return Colors.orangeAccent;
  if (rol == 'cajero') return Colors.greenAccent;
  if (rol == 'repartidor') return Colors.purpleAccent;
  return Colors.blueAccent; // mozo por defecto
}

/// Helper para obtener el icono según el rol del staff
IconData getIconRol(String? rol) {
  if (rol == 'admin') return Icons.admin_panel_settings;
  if (rol == 'cocinero') return Icons.soup_kitchen;
  if (rol == 'cajero') return Icons.point_of_sale;
  if (rol == 'repartidor') return Icons.motorcycle;
  return Icons.person; // mozo por defecto
}
