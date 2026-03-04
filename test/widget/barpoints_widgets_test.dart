import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/user/widgets/barpoints/reward_card.dart';
import 'package:barapp/ui/user/widgets/barpoints/medalla_hito.dart';
import 'package:barapp/ui/user/widgets/barpoints/historial_row.dart';

Widget _wrap(Widget w) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: w)),
    );

// ─────────────────────────────────────────────────────────────────
// RewardCard
// ─────────────────────────────────────────────────────────────────
void main() {
  group('RewardCard — estado bloqueado —', () {
    testWidgets('muestra los puntos requeridos', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 80,
        onCanjear: () {},
      )));
      expect(find.text('250 pts'), findsOneWidget);
    });

    testWidgets('muestra el porcentaje de descuento', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 80,
        onCanjear: () {},
      )));
      expect(find.text('12% descuento'), findsOneWidget);
    });

    testWidgets('muestra ícono de candado', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 80,
        onCanjear: () {},
      )));
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('muestra los puntos faltantes', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 80,
        onCanjear: () {},
      )));
      // 250 - 80 = 170 pts faltantes
      expect(find.textContaining('170 pts'), findsOneWidget);
    });

    testWidgets('NO muestra el botón "Canjear Cupón"', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 80,
        onCanjear: () {},
      )));
      expect(find.textContaining('Canjear'), findsNothing);
    });
  });

  group('RewardCard — estado desbloqueado —', () {
    testWidgets('muestra el botón "Canjear Cupón"', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 100,
        descuento: 5,
        desbloqueado: true,
        totalPuntos: 150,
        onCanjear: () {},
      )));
      expect(find.textContaining('Canjear'), findsOneWidget);
    });

    testWidgets('NO muestra ícono de candado', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 100,
        descuento: 5,
        desbloqueado: true,
        totalPuntos: 150,
        onCanjear: () {},
      )));
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('NO muestra texto de puntos faltantes', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 100,
        descuento: 5,
        desbloqueado: true,
        totalPuntos: 150,
        onCanjear: () {},
      )));
      expect(find.textContaining('Faltan'), findsNothing);
    });

    testWidgets('tap en Canjear dispara el callback', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 100,
        descuento: 5,
        desbloqueado: true,
        totalPuntos: 150,
        onCanjear: () => taps++,
      )));
      await tester.tap(find.textContaining('Canjear'));
      expect(taps, 1);
    });

    testWidgets('nivel 500 pts: muestra ícono de diamante', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 500,
        descuento: 30,
        desbloqueado: true,
        totalPuntos: 500,
        onCanjear: () {},
      )));
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('nivel 100/250/400 pts: muestra ícono de medalla', (tester) async {
      for (final pts in [100, 250, 400]) {
        await tester.pumpWidget(_wrap(RewardCard(
          puntos: pts,
          descuento: 5,
          desbloqueado: true,
          totalPuntos: 500,
          onCanjear: () {},
        )));
        expect(find.byIcon(Icons.military_tech), findsOneWidget,
            reason: 'Nivel $pts pts debería mostrar military_tech');
      }
    });
  });

  group('RewardCard — textos de puntos faltantes —', () {
    testWidgets('faltantes calculados correctamente (250 - 180 = 70)', (tester) async {
      await tester.pumpWidget(_wrap(RewardCard(
        puntos: 250,
        descuento: 12,
        desbloqueado: false,
        totalPuntos: 180,
        onCanjear: () {},
      )));
      expect(find.textContaining('70 pts'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // MedallaHito
  // ─────────────────────────────────────────────────────────────────
  group('MedallaHito — alcanzado —', () {
    testWidgets('nivel 500 alcanzado: muestra ícono de diamante', (tester) async {
      await tester.pumpWidget(_wrap(const MedallaHito(
        puntos: 500,
        descuento: 30,
        alcanzado: true,
      )));
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('nivel 100/250/400 alcanzado: muestra military_tech', (tester) async {
      for (final pts in [100, 250, 400]) {
        await tester.pumpWidget(_wrap(MedallaHito(
          puntos: pts,
          descuento: 5,
          alcanzado: true,
        )));
        expect(find.byIcon(Icons.military_tech), findsOneWidget,
            reason: 'nivel $pts deblería mostrar military_tech');
      }
    });

    testWidgets('alcanzado=true: color del ícono es el del nivel (no gris)',
        (tester) async {
      await tester.pumpWidget(_wrap(const MedallaHito(
        puntos: 400,
        descuento: 20,
        alcanzado: true,
      )));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, isNot(Colors.white.withValues(alpha: 0.25)));
      expect(icon.color, MedallaHito.colorParaNivel(400)); // Oro
    });
  });

  group('MedallaHito — no alcanzado —', () {
    testWidgets('no alcanzado: ícono de diamante en nivel 500', (tester) async {
      await tester.pumpWidget(_wrap(const MedallaHito(
        puntos: 500,
        descuento: 30,
        alcanzado: false,
      )));
      // Aun sin alcanzar muestra el mismo ícono (diamond) pero apagado
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('no alcanzado: color del ícono es gris opaco', (tester) async {
      await tester.pumpWidget(_wrap(const MedallaHito(
        puntos: 100,
        descuento: 5,
        alcanzado: false,
      )));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.white.withValues(alpha: 0.25));
    });
  });

  group('MedallaHito — colores por nivel (colorParaNivel) —', () {
    test('100 pts → color Bronce', () {
      expect(MedallaHito.colorParaNivel(100), const Color(0xFFCD7F32));
    });

    test('250 pts → color Plata', () {
      expect(MedallaHito.colorParaNivel(250), const Color(0xFFC0C0C0));
    });

    test('400 pts → color Oro', () {
      expect(MedallaHito.colorParaNivel(400), const Color(0xFFFFD700));
    });

    test('500 pts → color Diamante (cian)', () {
      expect(MedallaHito.colorParaNivel(500), const Color(0xFF4DD0E1));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // HistorialRow
  // ─────────────────────────────────────────────────────────────────
  group('HistorialRow — crédito (monto positivo) —', () {
    testWidgets('muestra el concepto', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Compra en Bar de Moe',
        monto: 3,
        fecha: null,
      )));
      expect(find.text('Compra en Bar de Moe'), findsOneWidget);
    });

    testWidgets('crédito: muestra prefijo "+" antes del monto', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Compra',
        monto: 5,
        fecha: null,
      )));
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('crédito: color del monto es greenAccent', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Compra',
        monto: 5,
        fecha: null,
      )));
      final text = tester.widget<Text>(find.text('+5'));
      expect(text.style?.color, Colors.greenAccent);
    });
  });

  group('HistorialRow — débito (monto negativo) —', () {
    testWidgets('débito: monto se muestra con signo negativo', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Canje 100 pts',
        monto: -100,
        fecha: null,
      )));
      expect(find.text('-100'), findsOneWidget);
    });

    testWidgets('débito: color del monto es redAccent', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Canje',
        monto: -50,
        fecha: null,
      )));
      final text = tester.widget<Text>(find.text('-50'));
      expect(text.style?.color, Colors.redAccent);
    });
  });

  group('HistorialRow — con fecha —', () {
    testWidgets('fecha se muestra en formato dd/MM/yy', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Compra',
        monto: 2,
        fecha: DateTime(2025, 11, 5),
      )));
      expect(find.text('05/11/25'), findsOneWidget);
    });

    testWidgets('sin fecha: no se renderiza ninguna fecha', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Bono',
        monto: 10,
        fecha: null,
      )));
      // Solo debe haber el concepto + el monto — ninguna fecha
      expect(find.text('Bono'), findsOneWidget);
      expect(find.textContaining('/'), findsNothing);
    });
  });

  group('HistorialRow — monto cero —', () {
    testWidgets('monto 0 se considera crédito (prefijo "+")', (tester) async {
      await tester.pumpWidget(_wrap(HistorialRow(
        concepto: 'Ajuste',
        monto: 0,
        fecha: null,
      )));
      expect(find.text('+0'), findsOneWidget);
      final text = tester.widget<Text>(find.text('+0'));
      expect(text.style?.color, Colors.greenAccent);
    });
  });
}
