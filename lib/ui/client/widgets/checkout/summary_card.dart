import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el resumen de subtotales y total del pedido
/// 
/// Diseño premium con colores destacados para el total final.
class CheckoutSummaryCard extends StatelessWidget {
  final double subtotal;
  final double? shippingCost;
  final double? discountAmount;
  final double? discountPorcentaje;
  final bool isBarPointsCupon;
  final double total;

  const CheckoutSummaryCard({
    super.key,
    required this.subtotal,
    this.shippingCost,
    this.discountAmount,
    this.discountPorcentaje,
    this.isBarPointsCupon = false,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: "Subtotal productos",
            amount: subtotal,
          ),
          if (discountAmount != null && discountAmount! > 0)
            _PriceRow(
              label: isBarPointsCupon && discountPorcentaje != null
                  ? "Descuento BarPoints (${discountPorcentaje!.toInt()}%)"
                  : "Descuento",
              amount: -discountAmount!,
              isHighlight: true,
              isDiscount: true,
            ),
          if (shippingCost != null && shippingCost! > 0)
            _PriceRow(
              label: "Costo de envío",
              amount: shippingCost!,
              isHighlight: true,
            ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "\$${NumberFormat("#,##0", "es_AR").format(total)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para mostrar una fila de precio
class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isHighlight;
  final bool isDiscount;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isHighlight = false,
    this.isDiscount = false,
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
            style: TextStyle(
              color: isHighlight ? Colors.purpleAccent : Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            isDiscount 
                ? "-\$${NumberFormat("#,##0", "es_AR").format(amount.abs())}"
                : "\$${NumberFormat("#,##0", "es_AR").format(amount)}",
            style: TextStyle(
              color: isDiscount 
                  ? Colors.greenAccent 
                  : (isHighlight ? Colors.purpleAccent : Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
