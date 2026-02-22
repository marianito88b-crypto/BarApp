import 'package:flutter/material.dart';

/// Widget que muestra los botones de acción del proveedor
/// 
/// Incluye botones para "Pago Parcial" y "Saldar Todo"
class ProveedorActionButtons extends StatelessWidget {
  final VoidCallback onPagoParcial;
  final VoidCallback onSaldarTodo;

  const ProveedorActionButtons({
    super.key,
    required this.onPagoParcial,
    required this.onSaldarTodo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF151515),
      child: Row(
        children: [
          // Botón Pago Parcial
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orangeAccent),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPagoParcial,
              icon: const Icon(Icons.add_card, color: Colors.orangeAccent),
              label: const Text(
                "PAGO PARCIAL",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Botón Liquidar Todo
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onSaldarTodo,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                "SALDAR TODO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
