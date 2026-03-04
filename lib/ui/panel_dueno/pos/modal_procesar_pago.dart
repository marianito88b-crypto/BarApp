import 'package:flutter/material.dart';

import '../../../../services/coupons_service.dart';

/// Modal para procesar el cobro de una mesa (pedido en sala/mesa física).
/// Incluye opción de código de descuento. Los cupones BarPoints se rechazan (solo Delivery/Retiro).
class ModalProcesarPago extends StatefulWidget {
  final double totalAPagar;
  final String placeId;

  const ModalProcesarPago({
    super.key,
    required this.totalAPagar,
    required this.placeId,
  });

  @override
  State<ModalProcesarPago> createState() => _ModalProcesarPagoState();
}

class _ModalProcesarPagoState extends State<ModalProcesarPago> {
  final List<Map<String, dynamic>> _pagosRegistrados = [];
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();

  double _descuentoAplicado = 0;
  String? _codigoAplicado;
  bool _validandoCodigo = false;

  double get _totalConDescuento => (widget.totalAPagar - _descuentoAplicado).clamp(0.0, double.infinity);
  double get _totalPagado => _pagosRegistrados.fold(0, (acc, item) => acc + (item['monto'] as double));
  double get _faltaPagar => _totalConDescuento - _totalPagado;

  @override
  void initState() {
    super.initState();
    _montoCtrl.text = widget.totalAPagar.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicarCodigoDescuento() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.isEmpty) return;

    setState(() => _validandoCodigo = true);
    try {
      // Mesa física: BarPoints bloqueados, solo cupones maestros
      final resultado = await CouponsService.validarCodigoParaMesa(
        codigo: codigo,
        placeId: widget.placeId,
      );

      if (resultado['valido'] == true) {
        final porcentaje = (resultado['descuentoPorcentaje'] as num?)?.toDouble() ?? 0;
        final descuento = widget.totalAPagar * (porcentaje / 100);
        setState(() {
          _descuentoAplicado = descuento;
          _codigoAplicado = codigo;
          _montoCtrl.text = _totalConDescuento.toStringAsFixed(0);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Código aplicado: ${porcentaje.toInt()}% (-\$${descuento.toStringAsFixed(0)})'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado['mensaje']?.toString() ?? 'Código inválido'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _validandoCodigo = false);
    }
  }

  void _agregarPago(String metodo) {
    // 1. Determinar monto: Si el input está vacío o es 0, usamos lo que falta.
    double montoIngresado = double.tryParse(_montoCtrl.text) ?? 0;
    
 
    if (montoIngresado <= 0) {
      montoIngresado = _faltaPagar;
    }

    // 2. Validación: No dejar pagar más de la deuda (opcional, pero recomendado)
    if (montoIngresado > _faltaPagar + 0.1) { // +0.1 por redondeo decimal
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El monto excede la deuda."), backgroundColor: Colors.red));
       return;
    }

    setState(() {
      _pagosRegistrados.add({
        'metodo': metodo,
        'monto': montoIngresado,
        'fecha': DateTime.now() // Útil para arqueos
      });

      // 3. Limpiar input y actualizar sugerencia para el próximo pago
      double nuevoResto = _totalConDescuento - _totalPagado;
      _montoCtrl.text = nuevoResto > 0 ? nuevoResto.toStringAsFixed(0) : ''; 
    });
  }

  void _eliminarPago(int index) {
    setState(() {
      _pagosRegistrados.removeAt(index);
      _montoCtrl.text = _faltaPagar.toStringAsFixed(0); // Recalcular sugerencia
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool completado = _faltaPagar <= 0.5; // Margen de error 50 centavos

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Column(
        children: [
          const Text("Procesar Cobro", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 5),
          Text(
            _descuentoAplicado > 0
                ? "\$${widget.totalAPagar.toStringAsFixed(0)} → \$${_totalConDescuento.toStringAsFixed(0)} (-${_descuentoAplicado.toStringAsFixed(0)})"
                : "\$${widget.totalAPagar.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. VISUALIZADOR DE ESTADO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: completado ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: completado ? Colors.green : Colors.redAccent)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(completado ? "CUBIERTO" : "FALTA PAGAR:", style: const TextStyle(color: Colors.white70)),
                  Text(
                    "\$${_faltaPagar.toStringAsFixed(0)}", 
                    style: TextStyle(
                      color: completado ? Colors.greenAccent : Colors.redAccent, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CÓDIGO DESCUENTO (opcional, mesa = BarPoints bloqueados)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoCtrl,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: "Código descuento (opcional)",
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _validandoCodigo ? null : _aplicarCodigoDescuento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: _validandoCodigo
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text("Aplicar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (_codigoAplicado != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text("$_codigoAplicado aplicado", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 2. INPUT MANUAL (Solo si falta pagar)
            if (!completado) ...[
               TextField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: "Monto a imputar",
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixText: "\$ ",
                  prefixStyle: TextStyle(color: Colors.orangeAccent, fontSize: 20),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                ),
              ),
              const SizedBox(height: 20),
              
              // BOTONES DE MEDIOS DE PAGO
              const Text("Seleccionar medio:", style: TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BtnPago(icon: Icons.money, label: "Efectivo", color: Colors.greenAccent, onTap: () => _agregarPago('efectivo')),
                  _BtnPago(icon: Icons.credit_card, label: "Tarjeta", color: Colors.blueAccent, onTap: () => _agregarPago('tarjeta')),
                  _BtnPago(icon: Icons.qr_code, label: "MP / QR", color: Colors.lightBlueAccent, onTap: () => _agregarPago('mercadopago')),
                ],
              ),
            ],

            const Divider(color: Colors.white10, height: 30),

            // 3. LISTA DE PAGOS INGRESADOS
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _pagosRegistrados.length,
                itemBuilder: (ctx, i) {
                  final p = _pagosRegistrados[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      p['metodo'] == 'efectivo' ? Icons.money : Icons.credit_card, 
                      color: Colors.white54
                    ),
                    title: Text(p['metodo'].toString().toUpperCase(), style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("\$${p['monto'].toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        GestureDetector(onTap: () => _eliminarPago(i), child: const Icon(Icons.close, color: Colors.redAccent, size: 18))
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: completado ? Colors.greenAccent : Colors.grey,
            foregroundColor: Colors.black
          ),
          onPressed: completado
            ? () => Navigator.pop(context, {
                'pagos': _pagosRegistrados,
                'totalFinal': _totalConDescuento,
                'descuentoAplicado': _descuentoAplicado,
                'codigoAplicado': _codigoAplicado,
              })
            : null,
          child: const Text("CONFIRMAR PAGO"),
        ),
      ],
    );
  }
}

class _BtnPago extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BtnPago({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ],
      ),
    );
  }
}