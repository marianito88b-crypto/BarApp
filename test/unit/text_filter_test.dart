import 'package:flutter_test/flutter_test.dart';
import 'package:barapp/services/moderation/text_filter_service.dart';

void main() {
  group('TextFilterService.hasBadWords —', () {
    test('texto limpio → false', () {
      expect(TextFilterService.hasBadWords('Excelente bar, lo recomiendo!'), isFalse);
    });

    test('cadena vacía → false', () {
      expect(TextFilterService.hasBadWords(''), isFalse);
    });

    test('mala palabra exacta minúsculas → true', () {
      expect(TextFilterService.hasBadWords('tonto'), isTrue);
    });

    test('mala palabra en mayúsculas → true (case-insensitive)', () {
      expect(TextFilterService.hasBadWords('TONTO'), isTrue);
    });

    test('mala palabra mixta → true', () {
      expect(TextFilterService.hasBadWords('ToNtO'), isTrue);
    });

    test('mala palabra dentro de una frase → true', () {
      expect(TextFilterService.hasBadWords('Eres un tonto, en serio'), isTrue);
    });

    test('subcadena que CONTIENE la mala palabra pero es otra palabra → false', () {
      // "notonto" no debería detectarse como "tonto" (word boundary)
      expect(TextFilterService.hasBadWords('notonto'), isFalse);
    });

    test('mala palabra con puntuación al lado → true', () {
      expect(TextFilterService.hasBadWords('¡tonto!'), isTrue);
    });

    test('mala palabra con acento en lista → true', () {
      expect(TextFilterService.hasBadWords('imbécil'), isTrue);
    });

    test('palabra sin acento (variante sin acento también en lista) → true', () {
      expect(TextFilterService.hasBadWords('imbecil'), isTrue);
    });

    test('texto normal que incluye letras de una mala palabra → false', () {
      // "malo" está en la lista, pero "malón" no (word boundary)
      // Nota: \b considera el acento como non-word char, así que
      // "malón" = m-a-l-ó-n, la 'ó' rompe el word → "mal" queda separado
      // y "malo" no matchea porque el patrón sería mal+o y la 'ó' no es 'o'
      expect(TextFilterService.hasBadWords('Este es un texto normal'), isFalse);
    });
  });

  group('TextFilterService.sanitizeText —', () {
    test('texto limpio → sin cambios', () {
      const texto = 'El ambiente era genial y la atención excelente.';
      expect(TextFilterService.sanitizeText(texto), texto);
    });

    test('cadena vacía → cadena vacía', () {
      expect(TextFilterService.sanitizeText(''), '');
    });

    test('mala palabra exacta → reemplazada con asteriscos de igual longitud', () {
      // "tonto" = 5 caracteres → "*****"
      expect(TextFilterService.sanitizeText('tonto'), '*****');
    });

    test('mala palabra en mayúsculas → censurada', () {
      expect(TextFilterService.sanitizeText('TONTO'), '*****');
    });

    test('mala palabra en una frase → solo la palabra censurada', () {
      expect(
        TextFilterService.sanitizeText('Eres un tonto total'),
        'Eres un ***** total',
      );
    });

    test('múltiples malas palabras diferentes → todas censuradas', () {
      final result = TextFilterService.sanitizeText('tonto y malo');
      expect(result, contains('*****')); // "tonto" → 5 asteriscos
      expect(result, contains('****'));  // "malo" → 4 asteriscos
      expect(result, isNot(contains('tonto')));
      expect(result, isNot(contains('malo')));
    });

    test('palabra con puntuación al lado → censurada, la puntuación intacta', () {
      final result = TextFilterService.sanitizeText('tonto!');
      expect(result, '*****!');
    });

    test('subcadena no es mala palabra → no modificada', () {
      // "notonto" no debe censurarse porque "tonto" no está en word-boundary
      expect(TextFilterService.sanitizeText('notonto'), 'notonto');
    });

    test('longitud de los asteriscos coincide con la palabra original', () {
      // "boludo" = 6 letras → "******"
      final result = TextFilterService.sanitizeText('boludo');
      expect(result, '******');
      expect(result.length, 6);
    });

    test('texto con mala palabra con acento (en lista) → censurada', () {
      final result = TextFilterService.sanitizeText('eres un imbécil');
      expect(result, isNot(contains('imbécil')));
      expect(result, contains('*'));
    });

    test('texto con variante sin acento (en lista) → censurada', () {
      final result = TextFilterService.sanitizeText('eres un imbecil');
      expect(result, isNot(contains('imbecil')));
    });
  });
}
