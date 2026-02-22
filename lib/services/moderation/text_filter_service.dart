// lib/services/moderation/text_filter_service.dart

class TextFilterService {
  // Lista expandible. Puedes mover esto a una Remote Config de Firebase en el futuro
  // para actualizar palabras sin actualizar la app.
  static final Set<String> _badWords = {
    'feo', 'fea', 'forra', 'forro',
    'malo', 'mala', 'estupido', 'estupida', 'estúpido', 'estúpida',
    'tonto', 'tonta', 'down', 'mogolico', 'mogolica',
    'puto', 'puta', 'pendejo', 'pendeja',
    'hdp', 'pija', 'verga', 'pene',
    'concha', 'mierda', 'caca',
    'culo', 'orto', 'choto', 'chota',
    'cajeta', 'boludo', 'boluda', 'pelotudo', 'pelotuda',
    'trola', 'trolo', 'tarado', 'tarada', 'imbecil', 'imbécil',
    'idiota', 'maricon', 'maricón',
    // ... añade más
  };

  /// Devuelve TRUE si hay malas palabras.
  /// Útil para validar antes de dejar enviar un comentario.
  static bool hasBadWords(String input) {
    if (input.isEmpty) return false;
    for (final badWord in _badWords) {
      // \b busca la palabra exacta, ignorando si tiene puntos o comas alrededor
      // caseSensitive: false ignora mayúsculas/minúsculas
      final regExp = RegExp(r'\b' + RegExp.escape(badWord) + r'\b', caseSensitive: false);
      if (regExp.hasMatch(input)) {
        return true; 
      }
    }
    return false;
  }

  /// Devuelve el texto censurado con asteriscos (ej: "Hola p***").
  static String sanitizeText(String input) {
    String result = input;
    for (final badWord in _badWords) {
      final regExp = RegExp(r'\b' + RegExp.escape(badWord) + r'\b', caseSensitive: false);
      result = result.replaceAllMapped(regExp, (match) {
        return '*' * (match.group(0)?.length ?? badWord.length);
      });
    }
    return result;
  }
}

  