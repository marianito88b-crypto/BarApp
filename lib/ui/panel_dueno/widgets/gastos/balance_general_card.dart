import 'package:flutter/material.dart';
import 'package:barapp/services/finanzas_service.dart';

/// Tarjeta que muestra el balance general (Ventas - Gastos = Neto)
class BalanceGeneralCard extends StatefulWidget {
  final String placeId;

  const BalanceGeneralCard({
    super.key,
    required this.placeId,
  });

  @override
  State<BalanceGeneralCard> createState() => _BalanceGeneralCardState();
}

class _BalanceGeneralCardState extends State<BalanceGeneralCard> {
  late final FinanzasService _finanzas;
  late final Stream<double> _ingresosStream;
  late final Stream<double> _gastosStream;

  @override
  void initState() {
    super.initState();
    _finanzas = FinanzasService(placeId: widget.placeId);
    _ingresosStream = _finanzas.getIngresosMensuales();
    _gastosStream = _finanzas.getGastosMensuales();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _ingresosStream,
      builder: (context, snapshotIngresos) {
        return StreamBuilder<double>(
          stream: _gastosStream,
          builder: (context, snapshotGastos) {
            double ingresos = snapshotIngresos.data ?? 0.0;
            double gastos = snapshotGastos.data ?? 0.0;
            double neto = ingresos - gastos;

            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _rowBalance(
                    "Ventas del Mes",
                    "+ \$${ingresos.toStringAsFixed(2)}",
                    Colors.greenAccent,
                  ),
                  const SizedBox(height: 10),
                  _rowBalance(
                    "Gastos del Mes",
                    "- \$${gastos.toStringAsFixed(2)}",
                    Colors.redAccent,
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  _rowBalance(
                    "RESULTADO NETO",
                    "\$${neto.toStringAsFixed(2)}",
                    neto >= 0 ? Colors.orangeAccent : Colors.red,
                    bold: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rowBalance(
    String label,
    String monto,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          monto,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
