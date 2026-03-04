import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/home/widgets/feed/home_filter_chip.dart';

/// Helper: envuelve el widget en un MaterialApp con fondo oscuro para
/// que los colores no sean sobreescritos por el tema por defecto.
Widget _wrap(Widget w) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: w)),
    );

void main() {
  group('HomeFilterChip —', () {
    testWidgets('muestra el label', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Populares', isActive: false, onTap: () {}),
      ));
      expect(find.text('Populares'), findsOneWidget);
    });

    testWidgets('estado inactivo: texto en blanco', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Cercanía', isActive: false, onTap: () {}),
      ));
      final text = tester.widget<Text>(find.text('Cercanía'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('estado activo: texto en negro', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Abierto', isActive: true, onTap: () {}),
      ));
      final text = tester.widget<Text>(find.text('Abierto'));
      expect(text.style?.color, Colors.black);
    });

    testWidgets('estado activo: texto en negrita', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Abierto', isActive: true, onTap: () {}),
      ));
      final text = tester.widget<Text>(find.text('Abierto'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('estado inactivo: peso normal (w500)', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Cercanía', isActive: false, onTap: () {}),
      ));
      final text = tester.widget<Text>(find.text('Cercanía'));
      expect(text.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('con icono: renderiza el Icon', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(
          label: 'Cercanos',
          isActive: false,
          onTap: () {},
          icon: Icons.near_me,
        ),
      ));
      expect(find.byIcon(Icons.near_me), findsOneWidget);
    });

    testWidgets('sin icono: no renderiza ningún Icon', (tester) async {
      await tester.pumpWidget(_wrap(
        HomeFilterChip(label: 'Populares', isActive: false, onTap: () {}),
      ));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('dispara onTap al ser tocado', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        HomeFilterChip(
          label: 'Abierto',
          isActive: false,
          onTap: () => taps++,
        ),
      ));
      await tester.tap(find.byType(HomeFilterChip));
      expect(taps, 1);
    });

    testWidgets('múltiples taps incrementan el contador', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        HomeFilterChip(
          label: 'Abierto',
          isActive: false,
          onTap: () => taps++,
        ),
      ));
      await tester.tap(find.byType(HomeFilterChip));
      await tester.tap(find.byType(HomeFilterChip));
      await tester.tap(find.byType(HomeFilterChip));
      expect(taps, 3);
    });

    testWidgets('rebuild con isActive cambiado refleja el nuevo color', (tester) async {
      bool active = false;
      late StateSetter outer;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            outer = setState;
            return _wrap(
              HomeFilterChip(
                label: 'Populares',
                isActive: active,
                onTap: () => outer(() => active = !active),
              ),
            );
          },
        ),
      );

      // Estado inicial: texto blanco (inactivo)
      expect(
        tester.widget<Text>(find.text('Populares')).style?.color,
        Colors.white,
      );

      // Tap → activa el chip
      await tester.tap(find.byType(HomeFilterChip));
      await tester.pump(); // deja que AnimatedContainer termine
      await tester.pump(const Duration(milliseconds: 250));

      // Estado activo: texto negro
      expect(
        tester.widget<Text>(find.text('Populares')).style?.color,
        Colors.black,
      );
    });
  });
}
