import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/client/widgets/checkout/summary_card.dart';

Widget _wrap(Widget w) => MaterialApp(theme: ThemeData.dark(), home: Scaffold(body: w));

// ────────────────────────────────────────────────────────────────
// Helpers de búsqueda de texto parcial
// ────────────────────────────────────────────────────────────────
Finder _textContains(String s) => find.textContaining(s);

void main() {
  group('CheckoutSummaryCard — solo subtotal —', () {
    testWidgets('muestra "Subtotal productos"', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1500,
        total: 1500,
      )));
      expect(_textContains('Subtotal productos'), findsOneWidget);
    });

    testWidgets('muestra el subtotal formateado con puntos (es_AR)', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1500,
        total: 1500,
      )));
      expect(find.text('\$1.500'), findsWidgets); // aparece en subtotal Y en total
    });

    testWidgets('sin descuento: NO muestra fila de descuento', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1000,
        total: 1000,
      )));
      expect(_textContains('Descuento'), findsNothing);
    });

    testWidgets('sin costo de envío: NO muestra fila de envío', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1000,
        total: 1000,
      )));
      expect(_textContains('envío'), findsNothing);
    });

    testWidgets('muestra "TOTAL" en mayúsculas', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1000,
        total: 1000,
      )));
      expect(find.text('TOTAL'), findsOneWidget);
    });
  });

  group('CheckoutSummaryCard — con descuento genérico —', () {
    testWidgets('muestra fila "Descuento" cuando discountAmount > 0', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 2000,
        discountAmount: 400,
        total: 1600,
      )));
      expect(_textContains('Descuento'), findsOneWidget);
    });

    testWidgets('descuento se muestra con signo negativo', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 2000,
        discountAmount: 400,
        total: 1600,
      )));
      expect(find.text('-\$400'), findsOneWidget);
    });

    testWidgets('total refleja el valor correcto post-descuento', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 2000,
        discountAmount: 400,
        total: 1600,
      )));
      // El total formateado
      expect(_textContains('1.600'), findsOneWidget);
    });

    testWidgets('discountAmount = 0 NO muestra fila de descuento', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1000,
        discountAmount: 0,
        total: 1000,
      )));
      expect(_textContains('Descuento'), findsNothing);
    });
  });

  group('CheckoutSummaryCard — con BarPoints —', () {
    testWidgets('label incluye "BarPoints" cuando isBarPointsCupon=true',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 3000,
        discountAmount: 600,
        discountPorcentaje: 20,
        isBarPointsCupon: true,
        total: 2400,
      )));
      expect(_textContains('BarPoints'), findsOneWidget);
    });

    testWidgets('label incluye el porcentaje de descuento en BarPoints',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 3000,
        discountAmount: 600,
        discountPorcentaje: 20,
        isBarPointsCupon: true,
        total: 2400,
      )));
      expect(_textContains('20%'), findsOneWidget);
    });

    testWidgets('sin BarPoints (isBarPointsCupon=false): label NO incluye "BarPoints"',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 3000,
        discountAmount: 600,
        isBarPointsCupon: false,
        total: 2400,
      )));
      expect(_textContains('BarPoints'), findsNothing);
    });
  });

  group('CheckoutSummaryCard — con costo de envío —', () {
    testWidgets('muestra "Costo de envío" cuando shippingCost > 0', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1500,
        shippingCost: 350,
        total: 1850,
      )));
      expect(_textContains('Costo de envío'), findsOneWidget);
    });

    testWidgets('costo de envío formateado correctamente', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1500,
        shippingCost: 350,
        total: 1850,
      )));
      expect(find.text('\$350'), findsOneWidget);
    });

    testWidgets('shippingCost = 0 NO muestra fila de envío', (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 1500,
        shippingCost: 0,
        total: 1500,
      )));
      expect(_textContains('envío'), findsNothing);
    });
  });

  group('CheckoutSummaryCard — combinación completa (subtotal + descuento + envío) —',
      () {
    testWidgets(
        'todas las filas presentes: subtotal, descuento, envío, total',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 5000,
        discountAmount: 500,
        discountPorcentaje: 10,
        isBarPointsCupon: true,
        shippingCost: 400,
        total: 4900,
      )));

      expect(_textContains('Subtotal productos'), findsOneWidget);
      expect(_textContains('BarPoints'), findsOneWidget);
      expect(_textContains('Costo de envío'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('total muestra el monto final pasado como parámetro',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 5000,
        discountAmount: 500,
        shippingCost: 400,
        total: 4900,
      )));
      // Total = $4.900
      expect(_textContains('4.900'), findsOneWidget);
    });

    testWidgets('formato es_AR con miles: punto separador en > 1000',
        (tester) async {
      await tester.pumpWidget(_wrap(const CheckoutSummaryCard(
        subtotal: 10000,
        total: 10000,
      )));
      // Aparece en la fila subtotal y en la fila total (mismos valores)
      expect(_textContains('10.000'), findsWidgets);
    });
  });
}
