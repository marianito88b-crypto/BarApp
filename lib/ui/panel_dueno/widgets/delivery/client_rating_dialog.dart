import 'package:flutter/material.dart';
import '../../../../services/rating_service.dart';

/// Diálogo: el BAR califica al CLIENTE tras completar un pedido.
///
/// RUTA B: Guarda en {col}/{userId}/reputacion_recibida/{orderId}
/// Campos: placeId, placeNombre, estrellas, etiquetas (List), comentarios.
class ClientRatingDialog extends StatefulWidget {
  final String userId;
  final String orderId;
  final String placeId;
  final String clienteNombre;

  const ClientRatingDialog({
    super.key,
    required this.userId,
    required this.orderId,
    required this.placeId,
    required this.clienteNombre,
  });

  @override
  State<ClientRatingDialog> createState() => _ClientRatingDialogState();
}

class _ClientRatingDialogState extends State<ClientRatingDialog> {
  int _estrellas = 0;
  bool _isSubmitting = false;
  final TextEditingController _comentariosController = TextEditingController();

  // Etiquetas disponibles para que el bar califique al cliente
  static const _opcionesEtiquetas = [
    ('Amable', Icons.sentiment_satisfied_alt_rounded),
    ('Atendió rápido', Icons.speed_rounded),
    ('Indicaciones claras', Icons.location_on_rounded),
    ('Puntual en retiro', Icons.access_time_rounded),
    ('Buen comprador', Icons.verified_user_rounded),
  ];

  final Set<String> _etiquetasSeleccionadas = {};

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
      title: Row(
        children: [
          const Icon(Icons.person_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Calificar Cliente",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
            // Nombre del cliente
            Text(
              widget.clienteNombre,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ── Estrellas ──────────────────────────────────────────
            const Text(
              "Calificación general:",
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
                        i < _estrellas
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
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
              "Características:",
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
                return ElevatedButton.icon(
                  onPressed: () => setState(() {
                    if (selected) {
                      _etiquetasSeleccionadas.remove(label);
                    } else {
                      _etiquetasSeleccionadas.add(label);
                    }
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected
                        ? Colors.orangeAccent
                        : Colors.white.withValues(alpha: 0.08),
                    foregroundColor: selected ? Colors.black : Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? Colors.orangeAccent
                            : Colors.white24,
                      ),
                    ),
                  ),
                  icon: Icon(icon, size: 15),
                  label: Text(label, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Comentarios ────────────────────────────────────────
            const Text(
              "Comentario (opcional):",
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
              maxLength: 200,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Escribe un comentario sobre el cliente...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                counterStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.orangeAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Este comentario es solo para feedback interno del servicio",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontStyle: FontStyle.italic,
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
              : const Text(
                  "Guardar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final resultado = await RatingService.calificarCliente(
        userId: widget.userId,
        orderId: widget.orderId,
        placeId: widget.placeId,
        estrellas: _estrellas,
        etiquetas: _etiquetasSeleccionadas.toList(),
        comentarios: _comentariosController.text.trim(),
      );

      if (mounted) {
        if (resultado['success'] == true) {
          final bonusOtorgado = resultado['bonusOtorgado'] == true;
          final totalRatings = resultado['totalRatings'] as int? ?? 0;
          final warning = resultado['warning'] as String?;

          Navigator.pop(context);

          if (bonusOtorgado) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.orangeAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "¡Felicidades!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "Por tu $totalRatingsª calificación el cliente recibió 10 BarPoints extra 🎁",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("¡Genial!"),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  warning != null
                      ? "✅ Calificación guardada ($warning)"
                      : "✅ Cliente calificado correctamente",
                ),
                backgroundColor: warning != null ? Colors.orange : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          final error = resultado['error'] as String?;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error != null ? "❌ $error" : "❌ Error al guardar",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
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
