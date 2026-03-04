import 'package:barapp/services/barpoints_service.dart';

/// Lógica pura de BarPoints: cálculo de progreso, niveles y faltantes.
///
/// Esta clase no tiene dependencias externas (sin Firebase, sin Flutter)
/// para facilitar el testing y la reutilización.
class BarPointsLogic {
  /// Devuelve el siguiente hito (puntos) que el usuario aún no ha alcanzado.
  /// Retorna `null` si el usuario ya llegó al nivel máximo.
  static int? siguienteHito(int puntos) {
    if (puntos >= BarPointsService.maxBarPoints) return null;
    final niveles = BarPointsService.nivelesCanje.keys.toList()..sort();
    try {
      return niveles.firstWhere((n) => puntos < n);
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el hito anterior (puntos) al nivel actual del usuario.
  /// Retorna `0` si el usuario no ha alcanzado ningún nivel todavía.
  static int hitoAnterior(int puntos) {
    final niveles = BarPointsService.nivelesCanje.keys.toList()..sort();
    return niveles.lastWhere((n) => n <= puntos, orElse: () => 0);
  }

  /// Progreso [0.0, 1.0] hacia el siguiente hito.
  /// Retorna `1.0` cuando el usuario está en el nivel máximo.
  static double progresoHaciaHito(int puntos) {
    if (puntos >= BarPointsService.maxBarPoints) return 1.0;
    final siguiente = siguienteHito(puntos);
    if (siguiente == null) return 1.0;
    final anterior = hitoAnterior(puntos);
    final rango = siguiente - anterior;
    return rango > 0 ? (puntos - anterior) / rango : 1.0;
  }

  /// `true` si el usuario ha desbloqueado el nivel [nivelPuntos].
  static bool nivelDesbloqueado(int puntosUsuario, int nivelPuntos) {
    return puntosUsuario >= nivelPuntos;
  }

  /// Puntos faltantes para el siguiente hito.
  /// Retorna `null` si el usuario ya está en el nivel máximo.
  static int? puntasFaltantes(int puntos) {
    final siguiente = siguienteHito(puntos);
    return siguiente != null ? siguiente - puntos : null;
  }

  /// Texto de progreso que se muestra debajo de la barra (p.ej. "Faltan 50 pts para 12%").
  /// Retorna `null` cuando se alcanzó el nivel máximo.
  static String? textoProgreso(int puntos) {
    final siguiente = siguienteHito(puntos);
    if (siguiente == null) return null;
    final descuento = BarPointsService.nivelesCanje[siguiente];
    final faltantes = siguiente - puntos;
    return 'Faltan $faltantes pts para $descuento%';
  }
}
