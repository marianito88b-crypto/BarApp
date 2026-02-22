import 'package:flutter/material.dart';

/// Widget que muestra el selector de método de pago con ChoiceChips
/// 
/// Maneja los métodos de pago y el desglose de 'Pago Mixto' con campos individuales.
/// Usa callbacks para comunicar cambios al padre.
class ExternaPaymentSelector extends StatefulWidget {
  final String? initialMethod;
  final double? total;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<Map<String, double>>? onMixedPaymentChanged;

  const ExternaPaymentSelector({
    super.key,
    this.initialMethod,
    this.total,
    required this.onMethodChanged,
    this.onMixedPaymentChanged,
  });

  @override
  State<ExternaPaymentSelector> createState() =>
      _ExternaPaymentSelectorState();
}

class _ExternaPaymentSelectorState extends State<ExternaPaymentSelector> {
  final List<String> _metodosPago = [
    'Efectivo',
    'MercadoPago',
    'Transferencia',
    'Mixto',
  ];
  late String _metodoSeleccionado;

  // Controllers para MIXTO
  final TextEditingController _efectivoCtrl = TextEditingController();
  final TextEditingController _mpCtrl = TextEditingController();
  final TextEditingController _transferenciaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _metodoSeleccionado = widget.initialMethod ?? 'Efectivo';
  }

  @override
  void dispose() {
    _efectivoCtrl.dispose();
    _mpCtrl.dispose();
    _transferenciaCtrl.dispose();
    super.dispose();
  }

  void _updateMixedPayment() {
    if (widget.onMixedPaymentChanged != null) {
      final efectivo = double.tryParse(_efectivoCtrl.text) ?? 0.0;
      final mp = double.tryParse(_mpCtrl.text) ?? 0.0;
      final transf = double.tryParse(_transferenciaCtrl.text) ?? 0.0;

      widget.onMixedPaymentChanged!({
        'efectivo': efectivo,
        'mercadopago': mp,
        'transferencia': transf,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Medio de pago",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _metodosPago.map((metodo) {
              final isSelected = _metodoSeleccionado == metodo;
              return ChoiceChip(
                label: Text(metodo),
                selected: isSelected,
                selectedColor: Colors.orangeAccent,
                backgroundColor: Colors.white10,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _metodoSeleccionado = metodo;
                  });
                  widget.onMethodChanged(metodo);
                  if (metodo != 'Mixto') {
                    _efectivoCtrl.clear();
                    _mpCtrl.clear();
                    _transferenciaCtrl.clear();
                    _updateMixedPayment();
                  }
                },
              );
            }).toList(),
          ),
          if (_metodoSeleccionado == 'Mixto') ...[
            const SizedBox(height: 16),
            _buildMontoInput("Efectivo", _efectivoCtrl),
            const SizedBox(height: 8),
            _buildMontoInput("MercadoPago / QR", _mpCtrl),
            const SizedBox(height: 8),
            _buildMontoInput("Transferencia", _transferenciaCtrl),
          ],
        ],
      ),
    );
  }

  Widget _buildMontoInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixText: "\$ ",
        prefixStyle: const TextStyle(color: Colors.greenAccent),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      onChanged: (_) => _updateMixedPayment(),
    );
  }
}
