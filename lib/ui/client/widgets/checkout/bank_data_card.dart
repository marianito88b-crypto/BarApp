import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que muestra la tarjeta azul con los datos bancarios para transferencia
/// 
/// Incluye botones de copiar para Alias y CBU, con feedback visual.
class BankDataCard extends StatelessWidget {
  final String? alias;
  final String? cbu;
  final String? banco;

  const BankDataCard({
    super.key,
    this.alias,
    this.cbu,
    this.banco,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos para transferir:",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Chequeo de datos vacíos
          if ((alias == null || alias!.isEmpty) &&
              (cbu == null || cbu!.isEmpty))
            const Text(
              "⚠️ Consultar CBU/Alias al confirmar.",
              style: TextStyle(color: Colors.orangeAccent),
            )
          else ...[
            if (alias != null && alias!.isNotEmpty)
              _CopyRow(label: "Alias", value: alias!),
            if (cbu != null && cbu!.isNotEmpty)
              _CopyRow(label: "CBU", value: cbu!),
            if (banco != null && banco!.isNotEmpty)
              Text(
                "Banco: $banco",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],

          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white38,
                size: 14,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Podrás enviar el comprobante después de confirmar.",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para mostrar una fila con botón de copiar
class _CopyRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(color: Colors.white54),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Copiado!"),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.copy,
                  size: 14,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
