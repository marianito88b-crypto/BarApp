import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_channel_selector.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_payment_selector.dart';
import 'package:barapp/ui/panel_dueno/logic/ventas_externas_logic.dart';

class VentaRapidaTab extends StatefulWidget {
  final String placeId;
  const VentaRapidaTab({super.key, required this.placeId});

  @override
  State<VentaRapidaTab> createState() => _VentaRapidaTabState();
}

class _VentaRapidaTabState extends State<VentaRapidaTab>
    with VentaExternaCheckoutMixin {
  // Controllers principales
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _notaCtrl = TextEditingController();

  // Estado de selección
  String _canalSeleccionado = 'PedidosYa';
  String? _canalCustom;
  String _metodoSeleccionado = 'Efectivo';
  Map<String, double> _pagoMixto = {};

  // Control de carga
  bool _isLoading = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Venta rápida",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Registrá una venta externa sin productos detallados "
            "(PedidosYa, WhatsApp, Uber Eats, etc.)",
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 24),
          _buildMontoTotal(),

          const SizedBox(height: 24),
          ExternaChannelSelector(
            initialChannel: _canalSeleccionado,
            onChannelChanged: (canal) {
              setState(() {
                _canalSeleccionado = canal;
              });
            },
            onCustomChannelChanged: (custom) {
              setState(() {
                _canalCustom = custom;
              });
            },
          ),

          const SizedBox(height: 24),
          ExternaPaymentSelector(
            initialMethod: _metodoSeleccionado,
            total: double.tryParse(_montoCtrl.text.replaceAll(',', '.')),
            onMethodChanged: (metodo) {
              setState(() {
                _metodoSeleccionado = metodo;
              });
            },
            onMixedPaymentChanged: (pagos) {
              setState(() {
                _pagoMixto = pagos;
              });
            },
          ),

          const SizedBox(height: 24),
          TextField(
            controller: _notaCtrl,
            decoration: InputDecoration(
              labelText: "Nota (opcional)",
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : _registrarVenta,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "REGISTRAR VENTA",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // WIDGETS
  // =========================

  Widget _buildMontoTotal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monto total",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: "\$ ",
              prefixStyle: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =========================
  // LÓGICA
  // =========================

  Future<void> _registrarVenta() async {
    // Validar monto
    final montoTotal = double.tryParse(_montoCtrl.text.replaceAll(',', '.'));

    if (montoTotal == null || montoTotal <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Ingresa un monto válido"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Definir Canal
      final String canalReal = (_canalSeleccionado == 'Otro' && _canalCustom != null)
          ? _canalCustom!
          : _canalSeleccionado;

      // Construir items ficticios para venta rápida
      final items = [
        {
          'cantidad': 1,
          'nombre': 'Venta Rápida ($canalReal)',
          'precio': montoTotal,
          'total': montoTotal,
          'id': 'GENERICO',
        }
      ];

      // Obtener la nota si fue ingresada
      final String? nota = _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim();

      // Usar el Mixin para validar y registrar
      final success = await validarYRegistrarVenta(
        placeId: widget.placeId,
        items: items,
        total: montoTotal,
        metodoSeleccionado: _metodoSeleccionado,
        pagoMixto: _pagoMixto,
        canal: _canalSeleccionado,
        canalCustom: _canalCustom,
        nota: nota,
      );

      if (!mounted) return;

      if (success) {
        // Limpieza completa del estado
        _montoCtrl.clear();
        _notaCtrl.clear();

        setState(() {
          _canalSeleccionado = 'PedidosYa';
          _canalCustom = null;
          _metodoSeleccionado = 'Efectivo';
          _pagoMixto = {};
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Venta Externa Registrada"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      // El manejo de errores ya está en el Mixin
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}