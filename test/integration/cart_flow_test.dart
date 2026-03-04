import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/client/widgets/menu/cart_bottom_bar.dart';

/// Widget que simula la pantalla de menú del cliente:
/// gestiona un carrito simple y renderiza [CartBottomBar].
class _FakeMenuScreen extends StatefulWidget {
  const _FakeMenuScreen();

  @override
  State<_FakeMenuScreen> createState() => _FakeMenuScreenState();
}

class _FakeMenuScreenState extends State<_FakeMenuScreen> {
  final Map<String, Map<String, dynamic>> _cart = {};
  bool _checkoutTapped = false;

  void _add(String id, String name, double price) {
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['cantidad'] = (_cart[id]!['cantidad'] as int) + 1;
      } else {
        _cart[id] = {'nombre': name, 'precio': price, 'cantidad': 1};
      }
    });
  }

  void _remove(String id) {
    setState(() {
      if (!_cart.containsKey(id)) return;
      final qty = (_cart[id]!['cantidad'] as int) - 1;
      if (qty <= 0) {
        _cart.remove(id);
      } else {
        _cart[id]!['cantidad'] = qty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('add_hamburgesa'),
            onPressed: () => _add('ham', 'Hamburguesa', 1500),
            child: const Text('+ Hamburgesa'),
          ),
          ElevatedButton(
            key: const Key('add_pizza'),
            onPressed: () => _add('piz', 'Pizza', 2200),
            child: const Text('+ Pizza'),
          ),
          ElevatedButton(
            key: const Key('remove_hamburgesa'),
            onPressed: () => _remove('ham'),
            child: const Text('- Hamburgesa'),
          ),
          if (_checkoutTapped)
            const Text('checkout_ok', key: Key('checkout_ok')),
        ],
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : CartBottomBar(
              cart: _cart,
              onTap: () => setState(() => _checkoutTapped = true),
            ),
    );
  }
}

Widget _wrap(Widget w) => MaterialApp(theme: ThemeData.dark(), home: w);

void main() {
  group('Cart flow —', () {
    testWidgets('carrito vacío: CartBottomBar no se renderiza', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));
      expect(find.byType(CartBottomBar), findsNothing);
    });

    testWidgets('agregar 1 item: CartBottomBar aparece con "1 items"',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();

      expect(find.byType(CartBottomBar), findsOneWidget);
      expect(find.text('1 items'), findsOneWidget);
    });

    testWidgets('agregar 1 item: muestra el precio correcto',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();

      // 1 hamburguesa × $1500 → "\$1.500"
      expect(find.text('\$1.500'), findsOneWidget);
    });

    testWidgets('agregar mismo item 3 veces: muestra "3 items" y total correcto',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();

      // 3 × $1500 = $4500
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('\$4.500'), findsOneWidget);
    });

    testWidgets('agregar 2 items distintos: el total es la suma', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa'))); // $1500
      await tester.tap(find.byKey(const Key('add_pizza')));       // $2200
      await tester.pump();

      // Total = $3700
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('\$3.700'), findsOneWidget);
    });

    testWidgets('quitar 1 de 2 unidades: vuelve a "1 items"', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();
      expect(find.text('2 items'), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_hamburgesa')));
      await tester.pump();

      expect(find.text('1 items'), findsOneWidget);
      expect(find.text('\$1.500'), findsOneWidget);
    });

    testWidgets(
        'quitar el único item del carrito: CartBottomBar desaparece',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();
      expect(find.byType(CartBottomBar), findsOneWidget);

      await tester.tap(find.byKey(const Key('remove_hamburgesa')));
      await tester.pump();

      expect(find.byType(CartBottomBar), findsNothing);
    });

    testWidgets('tap en "VER PEDIDO": dispara el callback de checkout',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      await tester.tap(find.byKey(const Key('add_hamburgesa')));
      await tester.pump();

      await tester.tap(find.text('VER PEDIDO'));
      await tester.pump();

      expect(find.byKey(const Key('checkout_ok')), findsOneWidget);
    });

    testWidgets(
        'miles con formato es_AR: usa punto como separador de miles',
        (tester) async {
      await tester.pumpWidget(_wrap(const _FakeMenuScreen()));

      // Agrego 10 pizzas: 10 × $2200 = $22.000
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const Key('add_pizza')));
      }
      await tester.pump();

      expect(find.text('\$22.000'), findsOneWidget);
    });
  });
}
