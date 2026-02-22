import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modal para registrar retiros de efectivo
/// Soporta dos tipos:
/// - 'gasto_casual': Retiro que se registra como gasto (afecta la caja)
/// - 'caja_fuerte': Retiro a caja fuerte (movimiento de alivio, no es gasto)
class RetiroModal extends StatefulWidget {
  final String placeId;
  final String tipoRetiro; // 'gasto_casual' o 'caja_fuerte'

  const RetiroModal({
    super.key,
    required this.placeId,
    this.tipoRetiro = 'gasto_casual',
  });

  @override
  State<RetiroModal> createState() => _RetiroModalState();
}

class _RetiroModalState extends State<RetiroModal> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.tipoRetiro == 'caja_fuerte'
                        ? Colors.amberAccent.withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.tipoRetiro == 'caja_fuerte'
                        ? Icons.account_balance
                        : Icons.money_off,
                    color: widget.tipoRetiro == 'caja_fuerte'
                        ? Colors.amberAccent
                        : Colors.redAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.tipoRetiro == 'caja_fuerte'
                        ? "RETIRO A CAJA FUERTE"
                        : "RETIRO - GASTO CASUAL",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.tipoRetiro == 'caja_fuerte'
                  ? "Movimiento de alivio de efectivo. No se registra como gasto."
                  : "Registra una salida de efectivo que se descontará de la caja",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),

            // Campo de monto
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: "Monto a retirar",
                labelStyle: const TextStyle(color: Colors.white54),
                prefixText: "\$ ",
                prefixStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            const SizedBox(height: 20),

            // Campo de notas/motivo
            TextField(
              controller: _notasController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Motivo o notas (opcional)",
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: "Ej: Solicitud del dueño, pago urgente, etc.",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            const SizedBox(height: 16),

            // Información sobre el tipo de retiro
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.tipoRetiro == 'caja_fuerte'
                    ? Colors.amberAccent.withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.tipoRetiro == 'caja_fuerte'
                      ? Colors.amberAccent.withValues(alpha: 0.4)
                      : Colors.redAccent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: widget.tipoRetiro == 'caja_fuerte'
                        ? Colors.amberAccent
                        : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.tipoRetiro == 'caja_fuerte'
                          ? "Este movimiento NO se registra como gasto. Es un alivio de efectivo para seguridad."
                          : "Este monto se descontará automáticamente del efectivo disponible en caja",
                      style: TextStyle(
                        color: widget.tipoRetiro == 'caja_fuerte'
                            ? Colors.amberAccent
                            : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("CANCELAR"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.tipoRetiro == 'caja_fuerte'
                          ? Colors.amberAccent
                          : Colors.redAccent,
                      foregroundColor: widget.tipoRetiro == 'caja_fuerte'
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _registrarRetiro,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "REGISTRAR RETIRO",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarRetiro() async {
    if (_montoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresá un monto válido"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double monto =
        double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0.0;

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El monto debe ser mayor a cero"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String operador = user?.email?.split('@')[0].toUpperCase() ?? 'Sistema';

      final placeRef =
          FirebaseFirestore.instance.collection('places').doc(widget.placeId);

      if (widget.tipoRetiro == 'caja_fuerte') {
        // Retiro a caja fuerte: movimiento de alivio, NO es un gasto
        final descripcion = _notasController.text.trim().isNotEmpty
            ? "Alivio a caja fuerte: ${_notasController.text.trim()} (Operador: $operador)"
            : "Alivio de efectivo a caja fuerte (Operador: $operador)";

        // Registrar en una colección especial de movimientos de caja fuerte
        await placeRef.collection('movimientos_caja_fuerte').add({
          'monto': monto,
          'descripcion': descripcion,
          'tipo': 'retiro',
          'fecha': FieldValue.serverTimestamp(),
          'operador': operador,
          'metodoPago': 'efectivo',
        });
      } else {
        // Retiro gasto casual: se registra como gasto normal
        final descripcion = _notasController.text.trim().isNotEmpty
            ? "Retiro - Gasto casual: ${_notasController.text.trim()} (Operador: $operador)"
            : "Retiro - Gasto casual (Operador: $operador)";

        await placeRef.collection('gastos').add({
          'monto': monto,
          'categoria': 'Retiro - Gasto Casual',
          'descripcion': descripcion,
          'estado': 'pagado',
          'metodoPago': 'efectivo',
          'tipo': 'retiro_gasto_casual', // Flag especial para identificar retiros casuales
          'fecha': FieldValue.serverTimestamp(),
          'operador': operador,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tipoRetiro == 'caja_fuerte'
                ? "✅ Movimiento a caja fuerte de \$${monto.toStringAsFixed(2)} registrado correctamente"
                : "✅ Retiro de \$${monto.toStringAsFixed(2)} registrado correctamente",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar retiro: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
