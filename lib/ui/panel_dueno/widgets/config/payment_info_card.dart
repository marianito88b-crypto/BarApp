import 'package:flutter/material.dart';

/// Tarjeta de información de datos bancarios para transferencias
class PaymentInfoCard extends StatelessWidget {
  final TextEditingController cbuController;
  final TextEditingController aliasController;
  final TextEditingController bancoController;
  final TextEditingController titularController;
  final VoidCallback onGuardar;

  const PaymentInfoCard({
    super.key,
    required this.cbuController,
    required this.aliasController,
    required this.bancoController,
    required this.titularController,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text(
                "Datos para Transferencia",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Estos datos se mostrarán al cliente cuando elija pagar con transferencia.",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),

          _inputField(
            "CBU / CVU",
            cbuController,
            Icons.numbers,
            type: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _inputField("Alias", aliasController, Icons.tag),
          const SizedBox(height: 12),
          _inputField(
            "Banco / Billetera",
            bancoController,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _inputField("Titular de la cuenta", titularController, Icons.person),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Guardar Datos Bancarios"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                onGuardar();
              },
            ),
          ),
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
