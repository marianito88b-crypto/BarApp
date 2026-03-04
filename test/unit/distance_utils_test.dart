import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/utils/distance_utils.dart';

void main() {
  group('DistanceUtils.format —', () {
    test('null → cadena vacía', () {
      expect(DistanceUtils.format(null), '');
    });

    test('valor negativo → cadena vacía', () {
      expect(DistanceUtils.format(-1), '');
      expect(DistanceUtils.format(-100), '');
    });

    test('0 metros → "0 m"', () {
      expect(DistanceUtils.format(0), '0 m');
    });

    test('50 metros → "50 m" (ya múltiplo de 10)', () {
      expect(DistanceUtils.format(50), '50 m');
    });

    test('480 metros → "480 m"', () {
      expect(DistanceUtils.format(480), '480 m');
    });

    test('85 metros → "90 m" (redondea al múltiplo de 10 más cercano)', () {
      // 85 / 10 = 8.5 → round() = 9 → 9 * 10 = 90
      expect(DistanceUtils.format(85), '90 m');
    });

    test('999 metros → "1000 m" (redondea 99.9 → 100, todavía muestra metros)', () {
      // 999 < 1000, rama metros: (999/10).round() * 10 = 100 * 10 = 1000 m
      expect(DistanceUtils.format(999), '1000 m');
    });

    test('1000 metros → "1.0 km"', () {
      expect(DistanceUtils.format(1000), '1.0 km');
    });

    test('1500 metros → "1.5 km"', () {
      expect(DistanceUtils.format(1500), '1.5 km');
    });

    test('2000 metros → "2.0 km"', () {
      expect(DistanceUtils.format(2000), '2.0 km');
    });

    test('10000 metros → "10.0 km"', () {
      expect(DistanceUtils.format(10000), '10.0 km');
    });

    test('formato sub-km siempre termina en " m"', () {
      final result = DistanceUtils.format(350);
      expect(result, endsWith(' m'));
      expect(result, isNot(contains('km')));
    });

    test('formato sobre-km siempre termina en " km"', () {
      final result = DistanceUtils.format(5500);
      expect(result, endsWith(' km'));
      expect(result, isNot(endsWith(' m\n')));
    });
  });

  group('DistanceUtils.isNear —', () {
    test('null → false', () {
      expect(DistanceUtils.isNear(null), isFalse);
    });

    test('0 metros → true', () {
      expect(DistanceUtils.isNear(0), isTrue);
    });

    test('500 metros → true', () {
      expect(DistanceUtils.isNear(500), isTrue);
    });

    test('999 metros → true (justo debajo del umbral)', () {
      expect(DistanceUtils.isNear(999), isTrue);
    });

    test('999.9 metros → true (justo debajo del umbral)', () {
      expect(DistanceUtils.isNear(999.9), isTrue);
    });

    test('1000 metros → false (umbral exclusivo: < 1000)', () {
      expect(DistanceUtils.isNear(1000), isFalse);
    });

    test('1001 metros → false', () {
      expect(DistanceUtils.isNear(1001), isFalse);
    });

    test('5000 metros → false', () {
      expect(DistanceUtils.isNear(5000), isFalse);
    });
  });
}
