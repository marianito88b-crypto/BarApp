import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/services/barpoints_service.dart';
import 'package:barapp/utils/barpoints_logic.dart';

void main() {
  // ══════════════════════════════════════════════════════════════
  // BarPointsService — constantes y calcularPuntosEstimados
  // ══════════════════════════════════════════════════════════════
  group('BarPointsService.calcularPuntosEstimados —', () {
    test('total 0 → 0 puntos', () {
      expect(BarPointsService.calcularPuntosEstimados(0), 0);
    });

    test('total negativo → 0 puntos', () {
      expect(BarPointsService.calcularPuntosEstimados(-500), 0);
    });

    test('total menor a 1000 → 0 puntos', () {
      expect(BarPointsService.calcularPuntosEstimados(999), 0);
    });

    test('total exactamente 1000 → 1 punto', () {
      expect(BarPointsService.calcularPuntosEstimados(1000), 1);
    });

    test('total 1500 → 1 punto (floor)', () {
      expect(BarPointsService.calcularPuntosEstimados(1500), 1);
    });

    test('total 1999 → 1 punto (floor, no redondea)', () {
      expect(BarPointsService.calcularPuntosEstimados(1999), 1);
    });

    test('total 2000 → 2 puntos', () {
      expect(BarPointsService.calcularPuntosEstimados(2000), 2);
    });

    test('total 10000 → 10 puntos', () {
      expect(BarPointsService.calcularPuntosEstimados(10000), 10);
    });

    test('total 25500 → 25 puntos (floor de 25.5)', () {
      expect(BarPointsService.calcularPuntosEstimados(25500), 25);
    });
  });

  group('BarPointsService — constantes y nivelesCanje —', () {
    test('puntosPorMilPesos = 1.0', () {
      expect(BarPointsService.puntosPorMilPesos, 1.0);
    });

    test('maxBarPoints = 500', () {
      expect(BarPointsService.maxBarPoints, 500);
    });

    test('nivelesCanje tiene exactamente 4 niveles', () {
      expect(BarPointsService.nivelesCanje.length, 4);
    });

    test('nivel 100 pts → 5% descuento', () {
      expect(BarPointsService.nivelesCanje[100], 5);
    });

    test('nivel 250 pts → 12% descuento', () {
      expect(BarPointsService.nivelesCanje[250], 12);
    });

    test('nivel 400 pts → 20% descuento', () {
      expect(BarPointsService.nivelesCanje[400], 20);
    });

    test('nivel 500 pts → 30% descuento (nivel máximo)', () {
      expect(BarPointsService.nivelesCanje[500], 30);
    });

    test('todos los niveles son alcanzables (≤ maxBarPoints)', () {
      for (final pts in BarPointsService.nivelesCanje.keys) {
        expect(pts, lessThanOrEqualTo(BarPointsService.maxBarPoints));
      }
    });

    test('descuentos estrictamente crecientes con los puntos', () {
      final sorted = BarPointsService.nivelesCanje.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (int i = 1; i < sorted.length; i++) {
        expect(
          sorted[i].value,
          greaterThan(sorted[i - 1].value),
          reason: '${sorted[i].key} pts debería tener más descuento que ${sorted[i - 1].key} pts',
        );
      }
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — siguienteHito
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.siguienteHito —', () {
    test('0 pts → próximo hito: 100', () {
      expect(BarPointsLogic.siguienteHito(0), 100);
    });

    test('50 pts → próximo hito: 100', () {
      expect(BarPointsLogic.siguienteHito(50), 100);
    });

    test('100 pts (hito exacto) → próximo hito: 250', () {
      expect(BarPointsLogic.siguienteHito(100), 250);
    });

    test('249 pts → próximo hito: 250', () {
      expect(BarPointsLogic.siguienteHito(249), 250);
    });

    test('250 pts → próximo hito: 400', () {
      expect(BarPointsLogic.siguienteHito(250), 400);
    });

    test('399 pts → próximo hito: 400', () {
      expect(BarPointsLogic.siguienteHito(399), 400);
    });

    test('400 pts → próximo hito: 500', () {
      expect(BarPointsLogic.siguienteHito(400), 500);
    });

    test('499 pts → próximo hito: 500', () {
      expect(BarPointsLogic.siguienteHito(499), 500);
    });

    test('500 pts (máximo) → null', () {
      expect(BarPointsLogic.siguienteHito(500), isNull);
    });

    test('más de 500 pts → null', () {
      expect(BarPointsLogic.siguienteHito(600), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — hitoAnterior
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.hitoAnterior —', () {
    test('0 pts → hito anterior: 0', () {
      expect(BarPointsLogic.hitoAnterior(0), 0);
    });

    test('50 pts (antes de primer hito) → 0', () {
      expect(BarPointsLogic.hitoAnterior(50), 0);
    });

    test('100 pts exacto → 100', () {
      expect(BarPointsLogic.hitoAnterior(100), 100);
    });

    test('175 pts (entre 100 y 250) → 100', () {
      expect(BarPointsLogic.hitoAnterior(175), 100);
    });

    test('250 pts exacto → 250', () {
      expect(BarPointsLogic.hitoAnterior(250), 250);
    });

    test('400 pts exacto → 400', () {
      expect(BarPointsLogic.hitoAnterior(400), 400);
    });

    test('500 pts → 500', () {
      expect(BarPointsLogic.hitoAnterior(500), 500);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — progresoHaciaHito
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.progresoHaciaHito —', () {
    test('0 pts → 0.0 (0/100)', () {
      expect(BarPointsLogic.progresoHaciaHito(0), closeTo(0.0, 0.001));
    });

    test('50 pts → 0.5 (50/100)', () {
      expect(BarPointsLogic.progresoHaciaHito(50), closeTo(0.5, 0.001));
    });

    test('100 pts (hito exacto) → 0.0 (reinicia en tramo 100-250)', () {
      expect(BarPointsLogic.progresoHaciaHito(100), closeTo(0.0, 0.001));
    });

    test('175 pts → 0.5 (75/150 en tramo 100-250)', () {
      expect(BarPointsLogic.progresoHaciaHito(175), closeTo(0.5, 0.001));
    });

    test('250 pts (hito exacto) → 0.0 (reinicia en tramo 250-400)', () {
      expect(BarPointsLogic.progresoHaciaHito(250), closeTo(0.0, 0.001));
    });

    test('400 pts → 0.0 (reinicia en tramo 400-500)', () {
      expect(BarPointsLogic.progresoHaciaHito(400), closeTo(0.0, 0.001));
    });

    test('450 pts → 0.5 (50/100 en tramo 400-500)', () {
      expect(BarPointsLogic.progresoHaciaHito(450), closeTo(0.5, 0.001));
    });

    test('500 pts (máximo) → 1.0', () {
      expect(BarPointsLogic.progresoHaciaHito(500), closeTo(1.0, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — nivelDesbloqueado
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.nivelDesbloqueado —', () {
    test('50 pts, nivel 100 → bloqueado', () {
      expect(BarPointsLogic.nivelDesbloqueado(50, 100), isFalse);
    });

    test('100 pts, nivel 100 → desbloqueado (exacto)', () {
      expect(BarPointsLogic.nivelDesbloqueado(100, 100), isTrue);
    });

    test('200 pts, nivel 100 → desbloqueado (supera el nivel)', () {
      expect(BarPointsLogic.nivelDesbloqueado(200, 100), isTrue);
    });

    test('200 pts, nivel 250 → bloqueado', () {
      expect(BarPointsLogic.nivelDesbloqueado(200, 250), isFalse);
    });

    test('500 pts, nivel 500 → desbloqueado', () {
      expect(BarPointsLogic.nivelDesbloqueado(500, 500), isTrue);
    });

    test('500 pts desbloquea todos los niveles', () {
      for (final nivel in BarPointsService.nivelesCanje.keys) {
        expect(BarPointsLogic.nivelDesbloqueado(500, nivel), isTrue,
            reason: 'Nivel $nivel debería estar desbloqueado con 500 pts');
      }
    });

    test('0 pts bloquea todos los niveles', () {
      for (final nivel in BarPointsService.nivelesCanje.keys) {
        expect(BarPointsLogic.nivelDesbloqueado(0, nivel), isFalse,
            reason: 'Nivel $nivel debería estar bloqueado con 0 pts');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — puntasFaltantes
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.puntasFaltantes —', () {
    test('0 pts → faltan 100', () {
      expect(BarPointsLogic.puntasFaltantes(0), 100);
    });

    test('50 pts → faltan 50', () {
      expect(BarPointsLogic.puntasFaltantes(50), 50);
    });

    test('100 pts → faltan 150 (para el siguiente nivel: 250)', () {
      expect(BarPointsLogic.puntasFaltantes(100), 150);
    });

    test('400 pts → faltan 100', () {
      expect(BarPointsLogic.puntasFaltantes(400), 100);
    });

    test('499 pts → falta 1', () {
      expect(BarPointsLogic.puntasFaltantes(499), 1);
    });

    test('500 pts (máximo) → null (no hay siguiente nivel)', () {
      expect(BarPointsLogic.puntasFaltantes(500), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BarPointsLogic — textoProgreso
  // ══════════════════════════════════════════════════════════════
  group('BarPointsLogic.textoProgreso —', () {
    test('0 pts → "Faltan 100 pts para 5%"', () {
      expect(BarPointsLogic.textoProgreso(0), 'Faltan 100 pts para 5%');
    });

    test('50 pts → "Faltan 50 pts para 5%"', () {
      expect(BarPointsLogic.textoProgreso(50), 'Faltan 50 pts para 5%');
    });

    test('100 pts → "Faltan 150 pts para 12%"', () {
      expect(BarPointsLogic.textoProgreso(100), 'Faltan 150 pts para 12%');
    });

    test('250 pts → "Faltan 150 pts para 20%"', () {
      expect(BarPointsLogic.textoProgreso(250), 'Faltan 150 pts para 20%');
    });

    test('400 pts → "Faltan 100 pts para 30%"', () {
      expect(BarPointsLogic.textoProgreso(400), 'Faltan 100 pts para 30%');
    });

    test('499 pts → "Faltan 1 pts para 30%"', () {
      expect(BarPointsLogic.textoProgreso(499), 'Faltan 1 pts para 30%');
    });

    test('500 pts (máximo) → null', () {
      expect(BarPointsLogic.textoProgreso(500), isNull);
    });
  });
}
