import 'package:flutter/material.dart';
import 'config_switch.dart';

/// Tarjeta de estado operacional del negocio con switches de configuración
class OperationalStatusCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onUpdateRealTime;
  final VoidCallback onMostrarAdvertenciaEfectivo;

  const OperationalStatusCard({
    super.key,
    required this.data,
    required this.onUpdateRealTime,
    required this.onMostrarAdvertenciaEfectivo,
  });

  @override
  Widget build(BuildContext context) {
    final bool aceptaPedidos = data['aceptaPedidos'] ?? true;
    final bool delivery = data['deliveryDisponible'] ?? false;
    final bool reservas = data['aceptaReservas'] ?? true;
    final bool efectivo = data['aceptaEfectivo'] ?? true;
    final bool menuVisible = data['menuVisible'] ?? true;

    return Column(
      children: [
        // --- SWITCH MAESTRO ---
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: aceptaPedidos
                  ? Colors.greenAccent.withValues(alpha: 0.3)
                  : Colors.redAccent.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: aceptaPedidos
                ? Colors.greenAccent.withValues(alpha: 0.05)
                : Colors.redAccent.withValues(alpha: 0.05),
          ),
          child: ConfigSwitch(
            label: "Recibir Pedidos (App)",
            subLabel: aceptaPedidos
                ? "Tienda ABIERTA al público"
                : "Tienda CERRADA (Pausada)",
            value: aceptaPedidos,
            icon: aceptaPedidos ? Icons.storefront : Icons.storefront_outlined,
            activeColor: Colors.greenAccent,
            onChanged: (v) => onUpdateRealTime({'aceptaPedidos': v}),
          ),
        ),

        // --- SWITCHES SECUNDARIOS ---
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: aceptaPedidos ? 1.0 : 0.4,
          child: IgnorePointer(
            ignoring: !aceptaPedidos,
            child: Column(
              children: [
                ConfigSwitch(
                  label: "Mostrar Menú / Carta",
                  subLabel: menuVisible
                      ? "Visible para todos los clientes"
                      : "OCULTO (Nadie ve los precios)",
                  value: menuVisible,
                  icon: menuVisible ? Icons.menu_book : Icons.menu_book_outlined,
                  activeColor: Colors.purpleAccent,
                  onChanged: (v) => onUpdateRealTime({'menuVisible': v}),
                ),
                const SizedBox(height: 10),
                ConfigSwitch(
                  label: "Delivery Disponible",
                  subLabel: delivery ? "Motos activas" : "Solo Retiro en Local",
                  value: delivery,
                  icon: Icons.delivery_dining,
                  activeColor: Colors.blueAccent,
                  onChanged: (v) => onUpdateRealTime({'deliveryDisponible': v}),
                ),
                const SizedBox(height: 10),
                ConfigSwitch(
                  label: "Aceptar Reservas",
                  subLabel: reservas ? "Sistema activo" : "Reservas pausadas",
                  value: reservas,
                  icon: Icons.calendar_today,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) => onUpdateRealTime({'aceptaReservas': v}),
                ),
                const SizedBox(height: 10),
                ConfigSwitch(
                  label: "Aceptar Efectivo",
                  subLabel: efectivo
                      ? "Cobro al entregar habilitado"
                      : "Solo Transferencia Previa",
                  value: efectivo,
                  icon: Icons.payments_outlined,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    if (val) {
                      onMostrarAdvertenciaEfectivo();
                    } else {
                      onUpdateRealTime({'aceptaEfectivo': false});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
