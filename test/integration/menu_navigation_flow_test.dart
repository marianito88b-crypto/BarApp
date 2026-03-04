import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/client/widgets/menu/category_chip_bar.dart';
import 'package:barapp/ui/client/widgets/menu/cart_bottom_bar.dart';

// ────────────────────────────────────────────────────────────────
// Mini-menú fake que combina CategoryChipBar + CartBottomBar
// Simula el flujo real: el usuario cambia de categoría y
// agrega productos al carrito.
// ────────────────────────────────────────────────────────────────
class _FakeCategoryMenuScreen extends StatefulWidget {
  final List<String> categories;
  const _FakeCategoryMenuScreen({required this.categories});

  @override
  State<_FakeCategoryMenuScreen> createState() =>
      _FakeCategoryMenuScreenState();
}

class _FakeCategoryMenuScreenState
    extends State<_FakeCategoryMenuScreen> {
  late String _selectedCategory;
  final Map<String, Map<String, dynamic>> _cart = {};
  bool _checkoutTapped = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
  }

  void _addToCart() {
    setState(() {
      const id = 'prod1';
      if (_cart.containsKey(id)) {
        _cart[id]!['cantidad'] = (_cart[id]!['cantidad'] as int) + 1;
      } else {
        _cart[id] = {'nombre': 'Producto', 'precio': 1000.0, 'cantidad': 1};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CategoryChipBar(
            categories: widget.categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) =>
                setState(() => _selectedCategory = cat),
          ),
          Text('Categoría activa: $_selectedCategory',
              key: const Key('active_cat_label')),
          ElevatedButton(
            key: const Key('add_product'),
            onPressed: _addToCart,
            child: const Text('Agregar producto'),
          ),
          if (_checkoutTapped)
            const Text('checkout_invoked', key: Key('checkout_invoked')),
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

const _cats = ['Pizzas', 'Hamburguesas', 'Bebidas', 'Postres'];

void main() {
  group('CategoryChipBar — renderizado inicial —', () {
    testWidgets('muestra todas las categorías como chips', (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));
      for (final cat in _cats) {
        expect(find.text(cat), findsOneWidget);
      }
    });

    testWidgets('la primera categoría está seleccionada al inicio', (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));
      expect(find.text('Categoría activa: Pizzas'), findsOneWidget);
    });
  });

  group('CategoryChipBar — selección de categoría —', () {
    testWidgets('tap en otra categoría actualiza la categoría activa', (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.text('Hamburguesas'));
      await tester.pump();

      expect(find.text('Categoría activa: Hamburguesas'), findsOneWidget);
    });

    testWidgets('tap en la categoría activa no rompe el estado', (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      // Tap en la categoría ya seleccionada
      await tester.tap(find.text('Pizzas'));
      await tester.pump();

      expect(find.text('Categoría activa: Pizzas'), findsOneWidget);
    });

    testWidgets('cambiar de categoría múltiples veces: el último tap persiste',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.text('Bebidas'));
      await tester.pump();
      await tester.tap(find.text('Postres'));
      await tester.pump();
      await tester.tap(find.text('Hamburguesas'));
      await tester.pump();

      expect(find.text('Categoría activa: Hamburguesas'), findsOneWidget);
    });

    testWidgets(
        'una sola categoría disponible: se selecciona y nada se rompe',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const _FakeCategoryMenuScreen(categories: ['Todo']),
      ));

      expect(find.text('Categoría activa: Todo'), findsOneWidget);
      await tester.tap(find.text('Todo'));
      await tester.pump();
      expect(find.text('Categoría activa: Todo'), findsOneWidget);
    });
  });

  group('Flujo combinado CategoryChipBar + CartBottomBar —', () {
    testWidgets(
        'carrito vacío: CartBottomBar no aparece aunque se cambie de categoría',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.text('Bebidas'));
      await tester.pump();

      expect(find.byType(CartBottomBar), findsNothing);
    });

    testWidgets(
        'agregar producto → CartBottomBar aparece; la categoría seleccionada no cambia',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.text('Hamburguesas'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add_product')));
      await tester.pump();

      expect(find.byType(CartBottomBar), findsOneWidget);
      // Cambiar de categoría no borra el carrito
      expect(find.text('Categoría activa: Hamburguesas'), findsOneWidget);
    });

    testWidgets(
        'cambiar de categoría con productos en carrito: el total se mantiene',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.byKey(const Key('add_product')));
      await tester.pump();

      // Hay $1.000 en el carrito
      expect(find.text('\$1.000'), findsOneWidget);

      // Cambiar de categoría
      await tester.tap(find.text('Bebidas'));
      await tester.pump();

      // El total debe seguir siendo $1.000
      expect(find.text('\$1.000'), findsOneWidget);
    });

    testWidgets(
        'tap en "VER PEDIDO" dispara callback sin importar la categoría activa',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      await tester.tap(find.byKey(const Key('add_product')));
      await tester.pump();

      // Cambio de categoría antes de confirmar
      await tester.tap(find.text('Postres'));
      await tester.pump();

      await tester.tap(find.text('VER PEDIDO'));
      await tester.pump();

      expect(find.byKey(const Key('checkout_invoked')), findsOneWidget);
    });

    testWidgets('agregar múltiples productos: el conteo es acumulativo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _FakeCategoryMenuScreen(categories: _cats),
      ));

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('add_product')));
      }
      await tester.pump();

      expect(find.text('4 items'), findsOneWidget);
      expect(find.text('\$4.000'), findsOneWidget);
    });
  });
}
