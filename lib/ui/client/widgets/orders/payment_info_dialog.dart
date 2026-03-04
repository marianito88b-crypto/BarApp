import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Widget que muestra un diálogo con los datos bancarios para transferencia
/// 
/// Permite copiar CBU y Alias al portapapeles con feedback visual.
class ClientPaymentInfoDialog extends StatefulWidget {
  final String placeId;
  final double total;

  const ClientPaymentInfoDialog({
    super.key,
    required this.placeId,
    required this.total,
  });

  @override
  State<ClientPaymentInfoDialog> createState() => _ClientPaymentInfoDialogState();
}

class _ClientPaymentInfoDialogState extends State<ClientPaymentInfoDialog> {
  late final Future<DocumentSnapshot> _placeFuture;

  @override
  void initState() {
    super.initState();
    _placeFuture = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _placeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final cbu = data['cbu'] ?? 'No configurado';
        final alias = data['alias'] ?? 'No configurado';
        final banco = data['banco'] ?? 'Desconocido';
        final titular = data['titularCuenta'] ?? 'Desconocido';

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.account_balance,
                color: Colors.blueAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                "Datos de Transferencia",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "Total a transferir: \$${NumberFormat("#,##0", "es_AR").format(widget.total)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DataRow(
                context: context,
                label: "Banco / Billetera",
                value: banco,
                copyable: false,
              ),
              const Divider(color: Colors.white10),
              _DataRow(
                context: context,
                label: "CBU / CVU",
                value: cbu,
                copyable: true,
              ),
              const Divider(color: Colors.white10),
              _DataRow(
                context: context,
                label: "Alias",
                value: alias,
                copyable: true,
              ),
              const Divider(color: Colors.white10),
              _DataRow(
                context: context,
                label: "Titular",
                value: titular,
                copyable: false,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "⚠️ Al realizar la transferencia, el dueño verificará el pago y aprobará tu pedido.",
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cerrar",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget auxiliar para mostrar una fila de datos con opción de copiar
class _DataRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;
  final bool copyable;

  const _DataRow({
    required this.context,
    required this.label,
    required this.value,
    required this.copyable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (copyable && value != 'No configurado') ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$label copiado!"),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
