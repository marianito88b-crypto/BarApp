import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/client/widgets/checkout/option_card.dart';

Widget _wrap(Widget w) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: w)),
    );

void main() {
  group('DeliveryOptionCard —', () {
    testWidgets('muestra el label', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Retiro en local',
          icon: Icons.storefront,
          isSelected: false,
          onTap: () {},
        ),
      ));
      expect(find.text('Retiro en local'), findsOneWidget);
    });

    testWidgets('muestra el ícono recibido', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Delivery',
          icon: Icons.delivery_dining,
          isSelected: false,
          onTap: () {},
        ),
      ));
      expect(find.byIcon(Icons.delivery_dining), findsOneWidget);
    });

    testWidgets('estado no seleccionado: texto en blanco54', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Delivery',
          icon: Icons.delivery_dining,
          isSelected: false,
          onTap: () {},
        ),
      ));
      final text = tester.widget<Text>(find.text('Delivery'));
      expect(text.style?.color, Colors.white54);
    });

    testWidgets('estado seleccionado: texto en negro', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Retiro',
          icon: Icons.storefront,
          isSelected: true,
          onTap: () {},
        ),
      ));
      final text = tester.widget<Text>(find.text('Retiro'));
      expect(text.style?.color, Colors.black);
    });

    testWidgets('estado seleccionado: texto en negrita', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Retiro',
          icon: Icons.storefront,
          isSelected: true,
          onTap: () {},
        ),
      ));
      final text = tester.widget<Text>(find.text('Retiro'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('estado seleccionado: ícono en negro', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Retiro',
          icon: Icons.storefront,
          isSelected: true,
          onTap: () {},
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.storefront));
      expect(icon.color, Colors.black);
    });

    testWidgets('estado no seleccionado: ícono en blanco54', (tester) async {
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Delivery',
          icon: Icons.delivery_dining,
          isSelected: false,
          onTap: () {},
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.delivery_dining));
      expect(icon.color, Colors.white54);
    });

    testWidgets('dispara onTap al tocar el widget', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        DeliveryOptionCard(
          label: 'Delivery',
          icon: Icons.delivery_dining,
          isSelected: false,
          onTap: () => taps++,
        ),
      ));
      await tester.tap(find.byType(DeliveryOptionCard));
      expect(taps, 1);
    });

    testWidgets('cambiar isSelected actualiza el color del texto', (tester) async {
      bool selected = false;
      late StateSetter outer;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            outer = setState;
            return _wrap(
              DeliveryOptionCard(
                label: 'Retiro',
                icon: Icons.storefront,
                isSelected: selected,
                onTap: () => outer(() => selected = !selected),
              ),
            );
          },
        ),
      );

      // Inicial: blanco54
      expect(
        tester.widget<Text>(find.text('Retiro')).style?.color,
        Colors.white54,
      );

      await tester.tap(find.byType(DeliveryOptionCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Post-tap: negro (seleccionado)
      expect(
        tester.widget<Text>(find.text('Retiro')).style?.color,
        Colors.black,
      );
    });
  });
}
