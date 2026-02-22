import 'package:flutter/material.dart';

/// Widget que muestra el stepper de estado del pedido con animaciones fluidas
/// 
/// Muestra los pasos: Pendiente -> Cocina -> En Camino/Retiro -> Entregado
/// Con animaciones suaves de 500ms para transiciones de estado.
class OrderStatusStepper extends StatelessWidget {
  final String status;
  final String? driverName;

  const OrderStatusStepper({
    super.key,
    required this.status,
    this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    Color color = Colors.grey;
    String text = "Procesando...";
    IconData icon = Icons.timer;

    switch (status) {
      case 'pendiente':
        currentStep = 1;
        color = Colors.orange;
        text = "⏳ Esperando que el local acepte tu pedido...";
        icon = Icons.hourglass_top;
        break;

      case 'confirmado':
        currentStep = 1;
        color = Colors.lightGreen;
        text = "✅ ¡Pedido Aceptado! Pronto entrará en cocina.";
        icon = Icons.check_circle_outline;
        break;

      case 'en_preparacion':
        currentStep = 2;
        color = Colors.blueAccent;
        text = "👨‍🍳 Cocinando tus platos ricos 🔥";
        icon = Icons.soup_kitchen;
        break;

      case 'preparado':
        currentStep = 2;
        color = Colors.deepOrangeAccent;
        text = "¡Pedido listo! Esperando repartidor 🛵";
        icon = Icons.watch_later_outlined;
        break;

      case 'en_camino':
        currentStep = 3;
        color = Colors.purpleAccent;
        text = driverName != null
            ? "$driverName está en camino 🛵"
            : "Tu pedido está en camino 🛵";
        icon = Icons.delivery_dining;
        break;

      case 'listo_para_retirar':
        currentStep = 3;
        color = Colors.tealAccent;
        text = "¡Listo! Pasa a retirar por el local 🏪";
        icon = Icons.storefront;
        break;

      case 'entregado':
        currentStep = 4;
        color = Colors.green;
        text = "Entregado. ¡Que lo disfrutes! 😋";
        icon = Icons.check_circle;
        break;

      case 'rechazado':
        currentStep = 0;
        color = Colors.redAccent;
        text = "El local canceló tu pedido ❌";
        icon = Icons.cancel;
        break;
    }

    if (status == 'rechazado') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepIndicator(
              active: currentStep >= 1,
              color: Colors.orangeAccent,
            ),
            _Line(
              active: currentStep >= 2,
              color: Colors.blueAccent,
            ),
            _StepIndicator(
              active: currentStep >= 2,
              color: status == 'preparado'
                  ? Colors.deepOrangeAccent
                  : Colors.blueAccent,
            ),
            _Line(
              active: currentStep >= 3,
              color: status == 'listo_para_retirar'
                  ? Colors.tealAccent
                  : Colors.purpleAccent,
            ),
            _StepIndicator(
              active: currentStep >= 3,
              color: status == 'listo_para_retirar'
                  ? Colors.tealAccent
                  : Colors.purpleAccent,
            ),
            _Line(
              active: currentStep >= 4,
              color: Colors.green,
            ),
            _StepIndicator(
              active: currentStep >= 4,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget que representa un indicador de paso con animación fluida
class _StepIndicator extends StatelessWidget {
  final bool active;
  final Color color;

  const _StepIndicator({
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500), // Animación fluida
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? color : const Color(0xFF333333),
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: Colors.white12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Widget que representa una línea entre pasos con animación fluida
class _Line extends StatelessWidget {
  final bool active;
  final Color color;

  const _Line({
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500), // Animación fluida
        height: 2,
        color: active ? color.withValues(alpha: 0.5) : const Color(0xFF333333),
      ),
    );
  }
}
