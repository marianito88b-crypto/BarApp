import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/utils/venue_utils.dart';

// Helpers para construir objetos de datos de local
Map<String, dynamic> _venue({
  bool aceptaPedidos = true,
  String? apertura,
  String? cierre,
  bool dobleTurno = false,
  String? apertura2,
  String? cierre2,
}) =>
    {
      'aceptaPedidos': aceptaPedidos,
      'horarioApertura': apertura ?? '',
      'horarioCierre': cierre ?? '',
      'tieneDobleTurno': dobleTurno,
      'horarioApertura2': apertura2 ?? '',
      'horarioCierre2': cierre2 ?? '',
    };

// Crea un DateTime con la hora dada (fecha arbitraria, solo importa HH:mm)
DateTime _at(int hour, int minute) =>
    DateTime(2024, 1, 15, hour, minute);

void main() {
  group('VenueUtils.isVenueOpen —', () {
    group('aceptaPedidos = false', () {
      test('cierra siempre aunque sea horario de apertura', () {
        final data = _venue(
          aceptaPedidos: false,
          apertura: '09:00',
          cierre: '22:00',
        );
        expect(VenueUtils.isVenueOpen(data, now: _at(12, 0)), isFalse);
      });
    });

    group('horarios no configurados', () {
      test('sin apertura ni cierre → cerrado', () {
        expect(VenueUtils.isVenueOpen(_venue(), now: _at(12, 0)), isFalse);
      });

      test('apertura "--:--" (placeholder UI) → cerrado', () {
        final data = _venue(apertura: '--:--', cierre: '--:--');
        expect(VenueUtils.isVenueOpen(data, now: _at(12, 0)), isFalse);
      });

      test('apertura null → cerrado', () {
        final data = <String, dynamic>{
          'aceptaPedidos': true,
          'horarioApertura': null,
          'horarioCierre': '22:00',
        };
        expect(VenueUtils.isVenueOpen(data, now: _at(12, 0)), isFalse);
      });

      test('formato inválido (solo hora, sin minutos) → cerrado', () {
        final data = _venue(apertura: '12', cierre: '22');
        expect(VenueUtils.isVenueOpen(data, now: _at(12, 0)), isFalse);
      });
    });

    group('turno simple (sin cruce de medianoche)', () {
      // Horario 09:00 – 22:00
      final data = _venue(apertura: '09:00', cierre: '22:00');

      test('antes de abrir (08:59) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(8, 59)), isFalse);
      });

      test('justo al abrir (09:00) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(9, 0)), isTrue);
      });

      test('en el medio (15:30) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(15, 30)), isTrue);
      });

      test('un minuto antes del cierre (21:59) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(21, 59)), isTrue);
      });

      test('exactamente al cerrar (22:00) → cerrado (extremo exclusivo)', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(22, 0)), isFalse);
      });

      test('despues del cierre (23:00) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(23, 0)), isFalse);
      });
    });

    group('turno que cruza medianoche (ej: bar nocturno)', () {
      // Horario 20:00 – 03:00
      final data = _venue(apertura: '20:00', cierre: '03:00');

      test('tarde → abierto (21:00)', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(21, 0)), isTrue);
      });

      test('medianoche → abierto (00:00)', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(0, 0)), isTrue);
      });

      test('madrugada dentro del rango (02:30) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(2, 30)), isTrue);
      });

      test('exactamente al cerrar (03:00) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(3, 0)), isFalse);
      });

      test('mañana (10:00) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(10, 0)), isFalse);
      });

      test('justo antes de abrir (19:59) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(19, 59)), isFalse);
      });
    });

    group('doble turno (almuerzo + cena)', () {
      // Turno 1: 09:00 – 15:00 | Turno 2: 19:00 – 23:00
      final data = _venue(
        apertura: '09:00',
        cierre: '15:00',
        dobleTurno: true,
        apertura2: '19:00',
        cierre2: '23:00',
      );

      test('en el primer turno (11:00) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(11, 0)), isTrue);
      });

      test('entre turnos (17:00) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(17, 0)), isFalse);
      });

      test('en el segundo turno (21:00) → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(21, 0)), isTrue);
      });

      test('despues del segundo turno (23:30) → cerrado', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(23, 30)), isFalse);
      });
    });

    group('doble turno con segundo turno mal configurado', () {
      final data = _venue(
        apertura: '09:00',
        cierre: '15:00',
        dobleTurno: true,
        apertura2: '--:--', // segundos horarios vacíos
        cierre2: '--:--',
      );

      test('en el primer turno → abierto', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(11, 0)), isTrue);
      });

      test('fuera del primer turno → cerrado aunque dobleTurno=true', () {
        expect(VenueUtils.isVenueOpen(data, now: _at(18, 0)), isFalse);
      });
    });
  });

  group('VenueUtils.getFormattedHours — ', () {
    test('turno simple → "HH:mm a HH:mm"', () {
      final data = _venue(apertura: '09:00', cierre: '22:00');
      expect(VenueUtils.getFormattedHours(data), '09:00 a 22:00');
    });

    test('sin horarios configurados → mensaje estándar', () {
      expect(
        VenueUtils.getFormattedHours(_venue()),
        'Horarios no configurados',
      );
    });

    test('doble turno completo → incluye ambos turnos', () {
      final data = _venue(
        apertura: '09:00',
        cierre: '15:00',
        dobleTurno: true,
        apertura2: '19:00',
        cierre2: '23:00',
      );
      expect(
        VenueUtils.getFormattedHours(data),
        '09:00 a 15:00 y 19:00 a 23:00',
      );
    });

    test('dobleTurno=true pero segundo turno vacío → solo muestra el primero',
        () {
      final data = _venue(
        apertura: '09:00',
        cierre: '15:00',
        dobleTurno: true,
        apertura2: '',
        cierre2: '',
      );
      expect(VenueUtils.getFormattedHours(data), '09:00 a 15:00');
    });
  });

  group('VenueUtils.getVenueStatusMessage — ', () {
    test('local abierto → empieza con "Abierto"', () {
      final data = _venue(apertura: '09:00', cierre: '22:00');
      final msg = VenueUtils.getVenueStatusMessage(data);
      // No podemos fijar la hora aquí, pero sí podemos verificar que el
      // mensaje empiece con "Abierto" o "Cerrado" y contenga los horarios.
      expect(msg, anyOf(startsWith('Abierto'), startsWith('Cerrado')));
      expect(msg, contains('09:00 a 22:00'));
    });

    test('local que nunca abre (aceptaPedidos=false) → "Cerrado"', () {
      final data = _venue(
        aceptaPedidos: false,
        apertura: '09:00',
        cierre: '22:00',
      );
      expect(VenueUtils.getVenueStatusMessage(data), startsWith('Cerrado'));
    });
  });
}
