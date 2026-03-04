import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/ui/panel_dueno/widgets/pos/pos_utils.dart';

void main() {
  // ─── PosUtils.safeDouble ─────────────────────────────────────────────────
  group('PosUtils.safeDouble —', () {
    group('null', () {
      test('retorna 0.0', () {
        expect(PosUtils.safeDouble(null), 0.0);
      });
    });

    group('int', () {
      test('positivo → double equivalente', () {
        expect(PosUtils.safeDouble(42), 42.0);
      });
      test('cero → 0.0', () {
        expect(PosUtils.safeDouble(0), 0.0);
      });
      test('negativo → double equivalente', () {
        expect(PosUtils.safeDouble(-10), -10.0);
      });
    });

    group('double', () {
      test('retorna el mismo valor', () {
        expect(PosUtils.safeDouble(3.14), 3.14);
      });
      test('cero → 0.0', () {
        expect(PosUtils.safeDouble(0.0), 0.0);
      });
    });

    group('String parseable', () {
      test('"12.5" → 12.5', () {
        expect(PosUtils.safeDouble('12.5'), 12.5);
      });
      test('"100" → 100.0', () {
        expect(PosUtils.safeDouble('100'), 100.0);
      });
      test('"0" → 0.0', () {
        expect(PosUtils.safeDouble('0'), 0.0);
      });
    });

    group('String no parseable', () {
      test('"abc" → 0.0', () {
        expect(PosUtils.safeDouble('abc'), 0.0);
      });
      test('"" → 0.0', () {
        expect(PosUtils.safeDouble(''), 0.0);
      });
    });

    group('tipo desconocido', () {
      test('List → 0.0', () {
        expect(PosUtils.safeDouble([1, 2, 3]), 0.0);
      });
      test('bool → 0.0', () {
        expect(PosUtils.safeDouble(true), 0.0);
      });
    });
  });

  // ─── PosUtils.safeInt ─────────────────────────────────────────────────────
  group('PosUtils.safeInt —', () {
    group('null', () {
      test('retorna 0', () {
        expect(PosUtils.safeInt(null), 0);
      });
    });

    group('int', () {
      test('positivo → mismo valor', () {
        expect(PosUtils.safeInt(7), 7);
      });
      test('cero → 0', () {
        expect(PosUtils.safeInt(0), 0);
      });
      test('negativo → mismo valor', () {
        expect(PosUtils.safeInt(-5), -5);
      });
    });

    group('double', () {
      test('9.9 → 9 (trunca)', () {
        expect(PosUtils.safeInt(9.9), 9);
      });
      test('1.0 → 1', () {
        expect(PosUtils.safeInt(1.0), 1);
      });
      test('-3.7 → -3 (trunca hacia cero)', () {
        expect(PosUtils.safeInt(-3.7), -3);
      });
    });

    group('String parseable', () {
      test('"8" → 8', () {
        expect(PosUtils.safeInt('8'), 8);
      });
      test('"0" → 0', () {
        expect(PosUtils.safeInt('0'), 0);
      });
    });

    group('String no parseable', () {
      test('"xyz" → 0', () {
        expect(PosUtils.safeInt('xyz'), 0);
      });
      test('"" → 0', () {
        expect(PosUtils.safeInt(''), 0);
      });
      test('"3.5" → 0 (int.tryParse falla con decimales)', () {
        expect(PosUtils.safeInt('3.5'), 0);
      });
    });

    group('tipo desconocido', () {
      test('Map → 0', () {
        expect(PosUtils.safeInt({'a': 1}), 0);
      });
    });
  });
}
