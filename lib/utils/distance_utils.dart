/// Utilidades para formatear y clasificar distancias.
class DistanceUtils {
  /// Umbral en metros por debajo del cual se considera "cerca"
  /// (muestra ícono de persona caminando en la UI).
  static const double nearThresholdMeters = 1000.0;

  /// Formatea una distancia en metros para mostrar al usuario.
  ///
  /// - `null` o valor negativo → cadena vacía (sin datos de ubicación)
  /// - `< 1000 m` → metros redondeados a múltiplo de 10  (e.g. "480 m")
  /// - `>= 1000 m` → kilómetros con un decimal          (e.g. "1.3 km")
  static String format(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters < 0) return '';
    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${(distanceMeters / 10).round() * 10} m';
  }

  /// Devuelve `true` cuando la distancia indica que el lugar está cerca
  /// (menos de [nearThresholdMeters]).
  static bool isNear(double? distanceMeters) {
    return distanceMeters != null && distanceMeters < nearThresholdMeters;
  }
}
