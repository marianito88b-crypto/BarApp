import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_channel_selector.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_payment_selector.dart';
import 'package:barapp/ui/panel_dueno/logic/ventas_externas_logic.dart';

class ModalCheckoutVentaExterna extends StatefulWidget {
  final String placeId;
  final List<Map<String, dynamic>> items;
  final double total;

  const ModalCheckoutVentaExterna({
    super.key,
    required this.placeId,
    required this.items,
    required this.total,
  });

  @override
  State<ModalCheckoutVentaExterna> createState() =>
      _ModalCheckoutVentaExternaState();
}

class _ModalCheckoutVentaExternaState extends State<ModalCheckoutVentaExterna>
    with VentaExternaCheckoutMixin {
  bool _isLoading = false;

  // Estado de selección
  String _canalSeleccionado = 'PedidosYa';
  String? _canalCustom;
  String _metodoSeleccionado = 'Efectivo';
  Map<String, double> _pagoMixto = {};

  Future<void> _confirmarVenta() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final success = await validarYRegistrarVenta(
        placeId: widget.placeId,
        items: widget.items,
        total: widget.total,
        metodoSeleccionado: _metodoSeleccionado,
        pagoMixto: _pagoMixto,
        canal: _canalSeleccionado,
        canalCustom: _canalCustom,
      );

      if (!mounted) return;

      if (success) {
        // Cerrar modal y retornar éxito
        Navigator.pop(context, true);
      } else {
        // El error ya fue mostrado por el Mixin
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error inesperado en checkout: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error inesperado: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        // Altura dinámica pero mínima
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text("Finalizar venta externa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text("TOTAL: \$${widget.total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // 🧭 CANAL
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

              // 💳 PAGO
              ExternaPaymentSelector(
                initialMethod: _metodoSeleccionado,
                total: widget.total,
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

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isLoading ? null : _confirmarVenta,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("CONFIRMAR VENTA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}