import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/utils/panel_logic.dart';

void main() {
  // ─── calcularTotalEsperado ────────────────────────────────────────────────
  group('calcularTotalEsperado —', () {
    test('solo saldo inicial, sin ventas ni gastos', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 500,
          ventasEfectivo: 0,
          gastosEfectivo: 0,
          totalCajaFuerte: 0,
        ),
        500.0,
      );
    });

    test('saldo + ventas efectivo', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 1000,
          ventasEfectivo: 2500,
          gastosEfectivo: 0,
          totalCajaFuerte: 0,
        ),
        3500.0,
      );
    });

    test('se descuentan los gastos en efectivo', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 1000,
          ventasEfectivo: 2500,
          gastosEfectivo: 300,
          totalCajaFuerte: 0,
        ),
        3200.0,
      );
    });

    test('se descuentan los retiros a caja fuerte', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 1000,
          ventasEfectivo: 2500,
          gastosEfectivo: 300,
          totalCajaFuerte: 700,
        ),
        2500.0,
      );
    });

    test('resultado puede ser negativo (gastos superiores a ventas)', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 0,
          ventasEfectivo: 100,
          gastosEfectivo: 500,
          totalCajaFuerte: 0,
        ),
        -400.0,
      );
    });

    test('todos los componentes en cero da cero', () {
      expect(
        calcularTotalEsperado(
          saldoInicial: 0,
          ventasEfectivo: 0,
          gastosEfectivo: 0,
          totalCajaFuerte: 0,
        ),
        0.0,
      );
    });
  });

  // ─── esTransferencia ─────────────────────────────────────────────────────
  group('esTransferencia —', () {
    group('debe retornar true', () {
      test('"transferencia"', () {
        expect(esTransferencia('transferencia'), isTrue);
      });
      test('"Transferencia" (mayúscula)', () {
        expect(esTransferencia('Transferencia'), isTrue);
      });
      test('"transf"', () {
        expect(esTransferencia('transf'), isTrue);
      });
      test('"banco"', () {
        expect(esTransferencia('banco'), isTrue);
      });
      test('"banco nación"', () {
        expect(esTransferencia('banco nación'), isTrue);
      });
      test('"Banco Galicia"', () {
        expect(esTransferencia('Banco Galicia'), isTrue);
      });
    });

    group('debe retornar false', () {
      test('"efectivo"', () {
        expect(esTransferencia('efectivo'), isFalse);
      });
      test('"mercadopago"', () {
        expect(esTransferencia('mercadopago'), isFalse);
      });
      test('"débito"', () {
        expect(esTransferencia('débito'), isFalse);
      });
      test('"crédito"', () {
        expect(esTransferencia('crédito'), isFalse);
      });
      test('vacío ""', () {
        expect(esTransferencia(''), isFalse);
      });
    });
  });

  // ─── clasificarMetodoPago ─────────────────────────────────────────────────
  group('clasificarMetodoPago —', () {
    group('efectivo', () {
      test('"efectivo"', () {
        expect(clasificarMetodoPago('efectivo'), 'efectivo');
      });
      test('"Efectivo" (mayúscula)', () {
        expect(clasificarMetodoPago('Efectivo'), 'efectivo');
      });
    });

    group('transferencia', () {
      test('"transferencia"', () {
        expect(clasificarMetodoPago('transferencia'), 'transferencia');
      });
      test('"banco"', () {
        expect(clasificarMetodoPago('banco'), 'transferencia');
      });
    });

    group('digital (catch-all)', () {
      test('"mercadopago"', () {
        expect(clasificarMetodoPago('mercadopago'), 'digital');
      });
      test('"débito"', () {
        expect(clasificarMetodoPago('débito'), 'digital');
      });
      test('"crédito"', () {
        expect(clasificarMetodoPago('crédito'), 'digital');
      });
    });
  });

  // ─── calcularCartTotal ────────────────────────────────────────────────────
  group('calcularCartTotal —', () {
    test('carrito vacío → 0.0', () {
      expect(calcularCartTotal([]), 0.0);
    });

    test('un ítem', () {
      final cart = [
        {'nombre': 'Empanada', 'precio': 350.0, 'cantidad': 3},
      ];
      expect(calcularCartTotal(cart), 1050.0);
    });

    test('varios ítems', () {
      final cart = [
        {'nombre': 'Empanada', 'precio': 350.0, 'cantidad': 2},
        {'nombre': 'Coca Cola', 'precio': 500.0, 'cantidad': 1},
        {'nombre': 'Cerveza', 'precio': 800.0, 'cantidad': 2},
      ];
      // 700 + 500 + 1600 = 2800
      expect(calcularCartTotal(cart), 2800.0);
    });

    test('precio y cantidad como int también funciona', () {
      final cart = [
        {'nombre': 'Vino', 'precio': 1200, 'cantidad': 1},
      ];
      expect(calcularCartTotal(cart), 1200.0);
    });
  });

  // ─── validarPagoMixto ─────────────────────────────────────────────────────
  group('validarPagoMixto —', () {
    test('suma exacta → válido', () {
      expect(
        validarPagoMixto({'efectivo': 500, 'mercadopago': 300, 'transferencia': 200}, 1000),
        isTrue,
      );
    });

    test('suma mayor pero dentro del margen +0.5 → válido', () {
      expect(
        validarPagoMixto({'efectivo': 1000.4, 'mercadopago': 0, 'transferencia': 0}, 1000),
        isTrue,
      );
    });

    test('suma dentro del margen -0.5 → válido', () {
      expect(
        validarPagoMixto({'efectivo': 999.6, 'mercadopago': 0, 'transferencia': 0}, 1000),
        isTrue,
      );
    });

    test('suma que excede el margen → inválido', () {
      expect(
        validarPagoMixto({'efectivo': 800, 'mercadopago': 0, 'transferencia': 0}, 1000),
        isFalse,
      );
    });

    test('mapa vacío con total 0 → válido', () {
      expect(validarPagoMixto({}, 0), isTrue);
    });

    test('mapa vacío con total > 0 → inválido', () {
      expect(validarPagoMixto({}, 500), isFalse);
    });
  });

  // ─── construirPagos ───────────────────────────────────────────────────────
  group('construirPagos —', () {
    group('pago simple', () {
      test('Efectivo → un pago con metodo "efectivo"', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Efectivo',
          pagoMixto: {},
          total: 1000,
        );
        expect(pagos, hasLength(1));
        expect(pagos.first['metodo'], 'efectivo');
        expect(pagos.first['monto'], 1000.0);
      });

      test('MercadoPago → un pago con metodo "mercadopago"', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'MercadoPago',
          pagoMixto: {},
          total: 750,
        );
        expect(pagos, hasLength(1));
        expect(pagos.first['metodo'], 'mercadopago');
        expect(pagos.first['monto'], 750.0);
      });

      test('Transferencia → un pago con metodo "transferencia"', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Transferencia',
          pagoMixto: {},
          total: 500,
        );
        expect(pagos, hasLength(1));
        expect(pagos.first['metodo'], 'transferencia');
      });
    });

    group('pago mixto', () {
      test('solo efectivo → un pago', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Mixto',
          pagoMixto: {'efectivo': 1000, 'mercadopago': 0, 'transferencia': 0},
          total: 1000,
        );
        expect(pagos, hasLength(1));
        expect(pagos.first['metodo'], 'efectivo');
      });

      test('efectivo + mercadopago → dos pagos', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Mixto',
          pagoMixto: {'efectivo': 600, 'mercadopago': 400, 'transferencia': 0},
          total: 1000,
        );
        expect(pagos, hasLength(2));
        expect(pagos.map((p) => p['metodo']), containsAll(['efectivo', 'mercadopago']));
      });

      test('los tres métodos → tres pagos', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Mixto',
          pagoMixto: {'efectivo': 300, 'mercadopago': 400, 'transferencia': 300},
          total: 1000,
        );
        expect(pagos, hasLength(3));
      });

      test('montos cero son omitidos', () {
        final pagos = construirPagos(
          metodoSeleccionado: 'Mixto',
          pagoMixto: {'efectivo': 0, 'mercadopago': 0, 'transferencia': 1000},
          total: 1000,
        );
        expect(pagos, hasLength(1));
        expect(pagos.first['metodo'], 'transferencia');
      });
    });
  });

  // ─── calcularChartIndex ───────────────────────────────────────────────────
  group('calcularChartIndex —', () {
    final DateTime ahora = DateTime(2024, 6, 15);

    test('fecha de hoy → índice days-1', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 6, 15), 7), 6);
    });

    test('fecha de ayer → índice days-2', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 6, 14), 7), 5);
    });

    test('primera fecha del rango → índice 0', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 6, 9), 7), 0);
    });

    test('fuera del rango → null', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 6, 8), 7), isNull);
    });

    test('muy antigua → null', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 1, 1), 7), isNull);
    });

    test('rango de 30 días — fecha de hoy → 29', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 6, 15), 30), 29);
    });

    test('rango de 30 días — 29 días atrás → 0', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 5, 17), 30), 0);
    });

    test('rango de 30 días — 30 días atrás → null', () {
      expect(calcularChartIndex(ahora, DateTime(2024, 5, 16), 30), isNull);
    });
  });
}
