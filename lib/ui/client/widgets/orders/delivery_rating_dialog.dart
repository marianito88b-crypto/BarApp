import 'package:flutter/material.dart';
import '../../../../services/rating_service.dart';

/// Diálogo: el CLIENTE califica al BAR tras recibir su pedido.
///
/// RUTA A: Guarda en places/{placeId}/ratings_recibidas/{orderId}
/// Campos: estrellas, etiquetas (List), comentarios (String).
class DeliveryRatingDialog extends StatefulWidget {
  final String orderId;
  final String placeId;

  const DeliveryRatingDialog({
    super.key,
    required this.orderId,
    required this.placeId,
  });

  @override
  State<DeliveryRatingDialog> createState() => _DeliveryRatingDialogState();
}

class _DeliveryRatingDialogState extends State<DeliveryRatingDialog> {
  int _estrellas = 0;

  // Etiquetas disponibles para el cliente (selección múltiple)
  static const _opcionesEtiquetas = [
    ('Llegó a tiempo', Icons.access_time),
    ('Comida caliente', Icons.local_fire_department),
    ('Buen trato', Icons.thumb_up_rounded),
    ('Empaque prolijo', Icons.inventory_2),
    ('Todo correcto', Icons.check_circle),
  ];

  final Set<String> _etiquetasSeleccionadas = {};
  final TextEditingController _comentariosController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Califica tu Entrega",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Estrellas ──────────────────────────────────────────
            const Text(
              "¿Cómo calificarías esta experiencia?",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _estrellas = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.orangeAccent,
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // ── Etiquetas ──────────────────────────────────────────
            const Text(
              "Detalles (opcional):",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _opcionesEtiquetas.map((opt) {
                final label = opt.$1;
                final icon = opt.$2;
                final selected = _etiquetasSeleccionadas.contains(label);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: selected ? Colors.orangeAccent : Colors.white54,
                      ),
                      const SizedBox(width: 5),
                      Text(label),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _etiquetasSeleccionadas.remove(label);
                    } else {
                      _etiquetasSeleccionadas.add(label);
                    }
                  }),
                  selectedColor: Colors.orangeAccent.withValues(alpha: 0.18),
                  checkmarkColor: Colors.orangeAccent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.orangeAccent : Colors.white70,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected ? Colors.orangeAccent : Colors.white24,
                  ),
                  backgroundColor: Colors.transparent,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Comentarios / Observaciones ────────────────────────
            const Text(
              "Observaciones (opcional):",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentariosController,
              maxLines: 3,
              maxLength: 250,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              decoration: InputDecoration(
                hintText: "¿Algo que quieras destacar o mejorar?",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                counterStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Omitir", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _estrellas == 0 ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text("Enviar", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await RatingService.calificarEntrega(
        orderId: widget.orderId,
        placeId: widget.placeId,
        estrellas: _estrellas,
        etiquetas: _etiquetasSeleccionadas.toList(),
        comentarios: _comentariosController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "✅ ¡Gracias por tu calificación!"
                  : "❌ No se pudo guardar la calificación",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
