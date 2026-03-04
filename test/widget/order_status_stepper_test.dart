import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/client/widgets/orders/order_status_stepper.dart';

Widget _wrap(Widget w) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: w)),
    );

void main() {
  group('OrderStatusStepper — textos de estado —', () {
    testWidgets('pendiente: muestra mensaje de espera', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'pendiente')),
      );
      expect(
        find.textContaining('Esperando que el local acepte'),
        findsOneWidget,
      );
    });

    testWidgets('confirmado: muestra mensaje de pedido aceptado', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'confirmado')),
      );
      expect(find.textContaining('Pedido Aceptado'), findsOneWidget);
    });

    testWidgets('en_preparacion: muestra mensaje de cocina', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'en_preparacion')),
      );
      expect(find.textContaining('Cocinando'), findsOneWidget);
    });

    testWidgets('preparado: muestra mensaje de pedido listo', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'preparado')),
      );
      expect(find.textContaining('Pedido listo'), findsOneWidget);
    });

    testWidgets('en_camino sin driverName: muestra texto genérico', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'en_camino')),
      );
      expect(find.textContaining('Tu pedido está en camino'), findsOneWidget);
    });

    testWidgets(
        'en_camino con driverName: muestra el nombre del repartidor', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(
          status: 'en_camino',
          driverName: 'Carlos',
        )),
      );
      expect(find.textContaining('Carlos está en camino'), findsOneWidget);
    });

    testWidgets(
        'en_camino con driverName: NO muestra el texto genérico', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(
          status: 'en_camino',
          driverName: 'Carlos',
        )),
      );
      expect(find.text('Tu pedido está en camino 🛵'), findsNothing);
    });

    testWidgets('listo_para_retirar: muestra mensaje de retiro', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'listo_para_retirar')),
      );
      expect(find.textContaining('Pasa a retirar'), findsOneWidget);
    });

    testWidgets('entregado: muestra mensaje de entrega', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'entregado')),
      );
      expect(find.textContaining('Entregado'), findsOneWidget);
    });

    testWidgets('estado desconocido: muestra "Procesando..."', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'estado_invalido')),
      );
      expect(find.textContaining('Procesando'), findsOneWidget);
    });
  });

  group('OrderStatusStepper — estado rechazado —', () {
    testWidgets('rechazado: muestra mensaje de cancelación', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'rechazado')),
      );
      expect(find.textContaining('canceló tu pedido'), findsOneWidget);
    });

    testWidgets('rechazado: muestra ícono de error', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'rechazado')),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('rechazado: NO muestra stepper (sin botones de paso)', (tester) async {
      // Los estados normales renderizan una Column con Row (stepper dots/lines).
      // 'rechazado' renderiza un único Container inline — no hay más de 1 Container
      // de stepper. Verificamos que el ícono de cancelación esté presente y
      // que NO aparezca el ícono de "borrar" que ningún otro estado usa.
      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'rechazado')),
      );
      // El ícono de error es específico del branch rechazado
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // No aparece ningún ícono propio del stepper normal
      expect(find.byIcon(Icons.hourglass_top), findsNothing);
    });
  });

  group('OrderStatusStepper — stepper se renderiza para estados normales —', () {
    testWidgets('pendiente: el widget se pinta sin overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'pendiente')),
      );
      // No debe haber overflow — simplemente verifica que el widget buildea
      expect(find.byType(OrderStatusStepper), findsOneWidget);
    });

    testWidgets('entregado: el widget se pinta sin overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const OrderStatusStepper(status: 'entregado')),
      );
      expect(find.byType(OrderStatusStepper), findsOneWidget);
    });
  });
}
