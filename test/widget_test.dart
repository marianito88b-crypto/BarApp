// Smoke test: verifica que el framework de tests funciona.
// Para tests que usen Firebase, configurar firebase_auth_mocks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Framework smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('BarApp')),
        ),
      ),
    );
    expect(find.text('BarApp'), findsOneWidget);
  });
}
