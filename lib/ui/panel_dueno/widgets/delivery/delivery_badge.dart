import 'package:flutter/material.dart';

/// Badge unificado para mostrar el estado de un pedido de delivery
class DeliveryBadge extends StatelessWidget {
  final String status;

  const DeliveryBadge({
    super.key,
    required this.status,
  });

  /// Obtiene el color, icono y label según el estado
  static ({Color color, IconData icon, String label}) getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return (
          color: Colors.orangeAccent,
          icon: Icons.notifications_active,
          label: 'NUEVO',
        );
      case 'confirmado':
        return (
          color: Colors.greenAccent,
          icon: Icons.check_circle_outline,
          label: 'CONFIRMADO',
        );
      case 'en_preparacion':
        return (
          color: Colors.blueAccent,
          icon: Icons.soup_kitchen,
          label: 'COCINA',
        );
      case 'preparado':
        return (
          color: Colors.pinkAccent,
          icon: Icons.report_problem,
          label: 'LISTO',
        );
      case 'en_camino':
        return (
          color: Colors.purpleAccent,
          icon: Icons.delivery_dining,
          label: 'EN CAMINO',
        );
      case 'listo_para_retirar':
        return (
          color: Colors.tealAccent,
          icon: Icons.shopping_bag,
          label: 'RETIRO',
        );
      case 'entregado':
        return (
          color: Colors.green,
          icon: Icons.check_circle,
          label: 'ENTREGADO',
        );
      case 'rechazado':
        return (
          color: Colors.redAccent,
          icon: Icons.cancel,
          label: 'CANCELADO',
        );
      case 'error':
        return (
          color: Colors.red,
          icon: Icons.error,
          label: 'ERROR STOCK',
        );
      default:
        return (
          color: Colors.grey,
          icon: Icons.help,
          label: 'DESCONOCIDO',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 14, color: info.color),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: TextStyle(
              color: info.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
