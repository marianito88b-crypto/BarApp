/// Utilidades para el sistema POS (Point of Sale)
/// 
/// Funciones de seguridad para conversión de tipos de datos
/// que evitan errores de tipo en tiempo de ejecución.
class PosUtils {
  /// Convierte un valor dinámico a double de forma segura.
  /// 
  /// Maneja diferentes tipos de entrada:
  /// - null → 0.0
  /// - int → double
  /// - double → double
  /// - String → double (si es parseable)
  /// - Otros → 0.0
  /// 
  /// Parámetros:
  /// - [value]: Valor a convertir
  /// 
  /// Retorna:
  /// - double: El valor convertido o 0.0 si no es posible
  static double safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convierte un valor dinámico a int de forma segura.
  /// 
  /// Maneja diferentes tipos de entrada:
  /// - null → 0
  /// - int → int
  /// - double → int (trunca)
  /// - String → int (si es parseable)
  /// - Otros → 0
  /// 
  /// Parámetros:
  /// - [value]: Valor a convertir
  /// 
  /// Retorna:
  /// - int: El valor convertido o 0 si no es posible
  static int safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
