import 'package:flutter/material.dart';

enum PaymentMethod {
  efectivo,
  tarjeta,
  mercadopago,
  transferencia,
  mixto,
  desconocido,
}

class PaymentMethodResult {
  final PaymentMethod method;
  final Color color;
  final IconData icon;
  final String label;

  const PaymentMethodResult({
    required this.method,
    required this.color,
    required this.icon,
    required this.label,
  });
}

class DashboardPaymentResolver {
  static PaymentMethodResult resolve(Map<String, dynamic> data) {
    final List<dynamic> pagos = data['pagos'] ?? [];
    String metodoRaiz =
        (data['metodoPago'] ?? data['metodoPrincipal'] ?? '')
            .toString()
            .toLowerCase();

    // Si hay múltiples pagos → MIXTO
    if (pagos.length > 1) {
      return const PaymentMethodResult(
        method: PaymentMethod.mixto,
        color: Colors.orangeAccent,
        icon: Icons.call_split,
        label: 'MIXTO',
      );
    }

    // Tomamos el método más confiable
    String metodo = metodoRaiz;
    if (metodo.isEmpty && pagos.isNotEmpty) {
      metodo = (pagos.first['metodo'] ?? '').toString().toLowerCase();
    }

    if (metodo.contains('transf')) {
      return const PaymentMethodResult(
        method: PaymentMethod.transferencia,
        color: Colors.purpleAccent,
        icon: Icons.account_balance,
        label: 'TRANSFERENCIA',
      );
    }

    if (metodo == 'efectivo') {
      return const PaymentMethodResult(
        method: PaymentMethod.efectivo,
        color: Colors.greenAccent,
        icon: Icons.money,
        label: 'EFECTIVO',
      );
    }

    if (metodo.contains('qr') || metodo.contains('mercado')) {
      return const PaymentMethodResult(
        method: PaymentMethod.mercadopago,
        color: Colors.lightBlueAccent,
        icon: Icons.qr_code,
        label: 'MP / QR',
      );
    }

    if (metodo.contains('tarjeta') || metodo.contains('debito')) {
      return const PaymentMethodResult(
        method: PaymentMethod.tarjeta,
        color: Colors.blueAccent,
        icon: Icons.credit_card,
        label: 'TARJETA',
      );
    }

    return const PaymentMethodResult(
      method: PaymentMethod.desconocido,
      color: Colors.grey,
      icon: Icons.help_outline,
      label: 'DESCONOCIDO',
    );
  }
}