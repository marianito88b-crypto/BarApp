import 'package:flutter/material.dart';
import 'config_switch.dart';

/// Tarjeta de configuración de precios de delivery
class DeliveryPricingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final TextEditingController envioBaseController;
  final TextEditingController envioKmExtraController;
  final Function(bool) onEnvioGratisChanged;
  final VoidCallback onGuardarCostos;

  const DeliveryPricingCard({
    super.key,
    required this.data,
    required this.envioBaseController,
    required this.envioKmExtraController,
    required this.onEnvioGratisChanged,
    required this.onGuardarCostos,
  });

  @override
  Widget build(BuildContext context) {
    final bool envioGratis = data['envioGratis'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Costos de Envío",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          ConfigSwitch(
            label: "Envío Gratis",
            subLabel: "Estrategia de Marketing",
            value: envioGratis,
            icon: Icons.card_giftcard,
            activeColor: Colors.purpleAccent,
            onChanged: onEnvioGratisChanged,
          ),

          if (envioGratis)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "¡Genial! Los clientes amarán el envío gratis.",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

          if (!envioGratis) ...[
            const SizedBox(height: 20),
            _inputField(
              "Costo Base (Radio cercano)",
              envioBaseController,
              Icons.location_on,
              type: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _inputField(
              "Costo por Km Extra (Lejanía)",
              envioKmExtraController,
              Icons.add_road,
              type: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onGuardarCostos,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_as, size: 18),
                    SizedBox(width: 8),
                    Text("Actualizar Tarifas"),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
