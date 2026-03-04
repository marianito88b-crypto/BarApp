import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/coupons_service.dart';

/// Diálogo para premiar a un cliente con un cupón de descuento
class RewardClientDialog extends StatefulWidget {
  final String userId;
  final String clienteNombre;
  final String placeId;
  final String placeName;

  const RewardClientDialog({
    super.key,
    required this.userId,
    required this.clienteNombre,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<RewardClientDialog> createState() => _RewardClientDialogState();
}

class _RewardClientDialogState extends State<RewardClientDialog> {
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  double _descuentoPorcentaje = 10.0;
  ValidezCupon _validezCupon = ValidezCupon.dias7;
  bool _isGenerating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _generarCodigo() {
    setState(() => _isGenerating = true);
    
    // Generar código único de 8 caracteres
    const uuid = Uuid();
    final codigo = uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    
    setState(() {
      _codigoController.text = codigo;
      _isGenerating = false;
    });
  }

  Future<void> _enviarPremio() async {
    if (_codigoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa o genera un código de cupón"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await CouponsService.crearCupon(
        userId: widget.userId,
        placeId: widget.placeId,
        placeName: widget.placeName,
        codigo: _codigoController.text.trim().toUpperCase(),
        descuentoPorcentaje: _descuentoPorcentaje,
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        validez: _validezCupon,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Cupón enviado a ${widget.clienteNombre}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Premiar Cliente",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clienteNombre,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Código del cupón
            const Text(
              "Código del cupón:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "Ej: REGALO123",
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text("Generar"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Porcentaje de descuento
            const Text(
              "Descuento (%):",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _descuentoPorcentaje,
              min: 5,
              max: 50,
              divisions: 9,
              label: "${_descuentoPorcentaje.toInt()}%",
              activeColor: Colors.orangeAccent,
              onChanged: (value) => setState(() => _descuentoPorcentaje = value),
            ),
            const SizedBox(height: 16),

            // Validez del cupón
            const Text(
              "Validez del cupón:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ValidezCupon>(
                  value: _validezCupon,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2C),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.orangeAccent),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: const [
                    DropdownMenuItem(
                      value: ValidezCupon.horas24,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.orangeAccent),
                          SizedBox(width: 10),
                          Text("24 Horas"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ValidezCupon.dias3,
                      child: Text("3 Días"),
                    ),
                    DropdownMenuItem(
                      value: ValidezCupon.dias7,
                      child: Text("7 Días (recomendado)"),
                    ),
                  ],
                  onChanged: (ValidezCupon? v) {
                    if (v != null) setState(() => _validezCupon = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción opcional
            const Text(
              "Descripción (opcional):",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Ej: Por ser un cliente destacado",
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text(
            "Cancelar",
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _enviarPremio,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.send),
          label: const Text("Enviar Premio"),
        ),
      ],
    );
  }
}
