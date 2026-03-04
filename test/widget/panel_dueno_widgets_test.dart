import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_cart_panel.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_payment_selector.dart';
import 'package:barapp/ui/panel_dueno/widgets/ventas_externas/externa_channel_selector.dart';

/// Envuelve el widget en un MaterialApp dark para que los estilos no
/// sean sobreescritos por el tema por defecto.
Widget _wrap(Widget w) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: w),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  ExternaCartPanel
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  group('ExternaCartPanel —', () {
    final List<Map<String, dynamic>> _pedido = [
      {'nombre': 'Empanada', 'precio': 350.0, 'cantidad': 2},
      {'nombre': 'Coca Cola', 'precio': 500.0, 'cantidad': 1},
    ];

    testWidgets('muestra el título del panel', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.text('Detalle del pedido'), findsOneWidget);
    });

    testWidgets('muestra el nombre de cada producto', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.textContaining('Empanada'), findsOneWidget);
      expect(find.textContaining('Coca Cola'), findsOneWidget);
    });

    testWidgets('muestra cantidad × nombre en ListTile', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.text('2x Empanada'), findsOneWidget);
      expect(find.text('1x Coca Cola'), findsOneWidget);
    });

    testWidgets('muestra el total formateado', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.text('\$1200'), findsOneWidget);
    });

    testWidgets('muestra botón CONTINUAR', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.text('CONTINUAR'), findsOneWidget);
    });

    testWidgets('botón CONTINUAR deshabilitado cuando pedido vacío',
        (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: const [],
        total: 0,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('botón CONTINUAR habilitado cuando hay ítems', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('icono de restar presente en cada ítem', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));
    });

    testWidgets('tapping un icono de restar llama onRestarProducto con índice',
        (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (i) => tappedIndex = i,
        onContinuar: () {},
      )));
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      expect(tappedIndex, 0);
    });

    testWidgets('tapping CONTINUAR llama onContinuar', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: _pedido,
        total: 1200,
        onRestarProducto: (_) {},
        onContinuar: () => called = true,
      )));
      await tester.tap(find.text('CONTINUAR'));
      expect(called, isTrue);
    });

    testWidgets('lista vacía no muestra ítems pero sí el panel', (tester) async {
      await tester.pumpWidget(_wrap(ExternaCartPanel(
        pedido: const [],
        total: 0,
        onRestarProducto: (_) {},
        onContinuar: () {},
      )));
      expect(find.text('Detalle del pedido'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  ExternaPaymentSelector
  // ─────────────────────────────────────────────────────────────────────────
  group('ExternaPaymentSelector —', () {
    testWidgets('muestra el título "Medio de pago"', (tester) async {
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        onMethodChanged: (_) {},
      )));
      expect(find.text('Medio de pago'), findsOneWidget);
    });

    testWidgets('muestra los cuatro métodos de pago como chips', (tester) async {
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        onMethodChanged: (_) {},
      )));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('MercadoPago'), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);
      expect(find.text('Mixto'), findsOneWidget);
    });

    testWidgets('selección inicial por defecto es "Efectivo"', (tester) async {
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        onMethodChanged: (_) {},
      )));
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final efectivoChip = chips.firstWhere(
          (c) => (c.label as Text).data == 'Efectivo');
      expect(efectivoChip.selected, isTrue);
    });

    testWidgets('initialMethod se respeta', (tester) async {
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        initialMethod: 'MercadoPago',
        onMethodChanged: (_) {},
      )));
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final mpChip = chips.firstWhere(
          (c) => (c.label as Text).data == 'MercadoPago');
      expect(mpChip.selected, isTrue);
    });

    testWidgets('seleccionar un chip llama onMethodChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        onMethodChanged: (m) => selected = m,
      )));
      await tester.tap(find.text('Transferencia'));
      await tester.pump();
      expect(selected, 'Transferencia');
    });

    testWidgets('campos mixtos NO visibles por defecto', (tester) async {
      await tester.pumpWidget(_wrap(ExternaPaymentSelector(
        onMethodChanged: (_) {},
      )));
      // Los campos de monto no deben estar en el árbol cuando el método es Efectivo
      expect(find.text('Efectivo'), findsOneWidget); // chip
      // El TextField de "Efectivo" (en modo mixto) no debería figurar
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isEmpty);
    });

    testWidgets('campos mixtos visibles al seleccionar "Mixto"', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 600,
          child: ExternaPaymentSelector(
            onMethodChanged: (_) {},
          ),
        ),
      ));
      await tester.tap(find.text('Mixto'));
      await tester.pump();
      expect(find.byType(TextField), findsWidgets);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  //  ExternaChannelSelector
  // ─────────────────────────────────────────────────────────────────────────
  group('ExternaChannelSelector —', () {
    testWidgets('muestra el título "Canal de venta"', (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      expect(find.text('Canal de venta'), findsOneWidget);
    });

    testWidgets('muestra los canales predefinidos', (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      expect(find.text('PedidosYa'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Uber Eats'), findsOneWidget);
      expect(find.text('Otro'), findsOneWidget);
    });

    testWidgets('selección inicial por defecto es "PedidosYa"', (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final pychip = chips.firstWhere(
          (c) => (c.label as Text).data == 'PedidosYa');
      expect(pychip.selected, isTrue);
    });

    testWidgets('initialChannel se respeta', (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        initialChannel: 'WhatsApp',
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final wchip = chips.firstWhere(
          (c) => (c.label as Text).data == 'WhatsApp');
      expect(wchip.selected, isTrue);
    });

    testWidgets('seleccionar un canal llama onChannelChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (c) => selected = c,
        onCustomChannelChanged: (_) {},
      )));
      await tester.tap(find.text('Uber Eats'));
      await tester.pump();
      expect(selected, 'Uber Eats');
    });

    testWidgets('campo "Otro" NO visible por defecto', (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('campo "Especificar canal" visible al seleccionar "Otro"',
        (tester) async {
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (_) {},
      )));
      await tester.tap(find.text('Otro'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('escribir en campo "Otro" llama onCustomChannelChanged',
        (tester) async {
      String? custom;
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (v) => custom = v,
      )));
      await tester.tap(find.text('Otro'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Rappi');
      await tester.pump();
      expect(custom, 'Rappi');
    });

    testWidgets('volver a un canal predicho llama onCustomChannelChanged con null',
        (tester) async {
      String? custom = 'algo';
      await tester.pumpWidget(_wrap(ExternaChannelSelector(
        onChannelChanged: (_) {},
        onCustomChannelChanged: (v) => custom = v,
      )));
      // Seleccionar "Otro"
      await tester.tap(find.text('Otro'));
      await tester.pump();
      // Volver a WhatsApp (limpia el canal custom)
      await tester.tap(find.text('WhatsApp'));
      await tester.pump();
      expect(custom, isNull);
    });
  });
}
