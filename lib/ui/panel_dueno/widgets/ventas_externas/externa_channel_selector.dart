import 'package:flutter/material.dart';

/// Widget que muestra el selector de canal de venta con ChoiceChips
/// 
/// Maneja los canales predefinidos y el campo 'Otro' con TextField cuando se selecciona.
/// Usa callbacks para comunicar cambios al padre.
class ExternaChannelSelector extends StatefulWidget {
  final String? initialChannel;
  final ValueChanged<String> onChannelChanged;
  final ValueChanged<String?> onCustomChannelChanged;

  const ExternaChannelSelector({
    super.key,
    this.initialChannel,
    required this.onChannelChanged,
    required this.onCustomChannelChanged,
  });

  @override
  State<ExternaChannelSelector> createState() => _ExternaChannelSelectorState();
}

class _ExternaChannelSelectorState extends State<ExternaChannelSelector> {
  final List<String> _canales = [
    'PedidosYa',
    'WhatsApp',
    'Uber Eats',
    'Otro',
  ];
  late String _canalSeleccionado;
  final TextEditingController _canalOtroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _canalSeleccionado = widget.initialChannel ?? 'PedidosYa';
  }

  @override
  void dispose() {
    _canalOtroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Canal de venta",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _canales.map((canal) {
            final isSelected = _canalSeleccionado == canal;
            return ChoiceChip(
              label: Text(canal),
              selected: isSelected,
              selectedColor: Colors.orangeAccent,
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  _canalSeleccionado = canal;
                });
                widget.onChannelChanged(canal);
                if (canal != 'Otro') {
                  widget.onCustomChannelChanged(null);
                  _canalOtroCtrl.clear();
                }
              },
            );
          }).toList(),
        ),
        if (_canalSeleccionado == 'Otro') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _canalOtroCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Especificar canal",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            onChanged: (value) {
              widget.onCustomChannelChanged(value.trim().isEmpty ? null : value.trim());
            },
          ),
        ],
      ],
    );
  }
}
