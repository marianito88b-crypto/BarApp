/// Utilidades centralizadas para verificar el estado de apertura de locales
class VenueUtils {
  /// Convierte una hora en formato "HH:mm" a minutos desde medianoche
  /// Retorna null si el formato es inválido
  static int? _parseTimeToMinutes(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == '--:--') {
      return null;
    }

    final parts = timeString.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null || hour < 0 || hour >= 24 || minute < 0 || minute >= 60) {
      return null;
    }

    return hour * 60 + minute;
  }

  /// Verifica si la hora actual (en minutos) está dentro de un rango de horas
  /// Maneja correctamente los rangos que cruzan medianoche
  static bool _isTimeInRange(int currentMinutes, int? startMinutes, int? endMinutes) {
    if (startMinutes == null || endMinutes == null) {
      return false;
    }

    // Si el cierre es menor que la apertura, significa que cruza medianoche
    if (endMinutes < startMinutes) {
      // Ejemplo: 20:00 (1200 min) a 03:00 (180 min)
      // Está abierto si: current >= 1200 (desde las 20:00) O current < 180 (hasta las 03:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Rango normal que no cruza medianoche
      // Ejemplo: 09:00 (540 min) a 15:00 (900 min)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Verifica si un local está abierto en este momento.
  ///
  /// [data]: Mapa con los datos del local desde Firestore
  /// [now]: Hora a evaluar — omitir en producción (usa `DateTime.now()`),
  ///        pasar un valor fijo en tests para resultados determinísticos.
  ///
  /// Retorna `true` si:
  /// 1. El local acepta pedidos (`aceptaPedidos == true`)
  /// 2. La hora actual está dentro del primer turno O del segundo turno (si existe)
  ///
  /// Maneja correctamente los horarios que cruzan medianoche (ej: 20:00 a 03:00)
  static bool isVenueOpen(Map<String, dynamic> data, {DateTime? now}) {
    // Si no acepta pedidos, está cerrado
    final aceptaPedidos = data['aceptaPedidos'] ?? true;
    if (!aceptaPedidos) {
      return false;
    }

    // Obtener hora actual en minutos desde medianoche
    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;

    // Verificar primer turno
    final horarioApertura = data['horarioApertura'] as String?;
    final horarioCierre = data['horarioCierre'] as String?;

    final apertura1Minutes = _parseTimeToMinutes(horarioApertura);
    final cierre1Minutes = _parseTimeToMinutes(horarioCierre);

    // Si no hay horarios configurados, considerar cerrado
    if (apertura1Minutes == null || cierre1Minutes == null) {
      return false;
    }

    // Verificar si está en el primer turno
    final isInFirstShift = _isTimeInRange(currentMinutes, apertura1Minutes, cierre1Minutes);

    // Si está en el primer turno, retornar true
    if (isInFirstShift) {
      return true;
    }

    // Si no tiene doble turno, solo verificar el primer turno
    final tieneDobleTurno = data['tieneDobleTurno'] ?? false;
    if (!tieneDobleTurno) {
      return false;
    }

    // Verificar segundo turno
    final horarioApertura2 = data['horarioApertura2'] as String?;
    final horarioCierre2 = data['horarioCierre2'] as String?;

    final apertura2Minutes = _parseTimeToMinutes(horarioApertura2);
    final cierre2Minutes = _parseTimeToMinutes(horarioCierre2);

    // Si no hay horarios del segundo turno configurados, solo considerar el primero
    if (apertura2Minutes == null || cierre2Minutes == null) {
      return false;
    }

    // Verificar si está en el segundo turno
    final isInSecondShift = _isTimeInRange(currentMinutes, apertura2Minutes, cierre2Minutes);

    return isInSecondShift;
  }

  /// Obtiene un string formateado con los horarios del local para mostrar al cliente
  ///
  /// [data]: Mapa con los datos del local desde Firestore
  ///
  /// Retorna un string como:
  /// - "09:00 a 15:00" (un solo turno)
  /// - "09:00 a 15:00 y 19:00 a 00:00" (doble turno)
  /// - "Horarios no configurados" (si no hay horarios válidos)
  static String getFormattedHours(Map<String, dynamic> data) {
    final horarioApertura = data['horarioApertura'] as String?;
    final horarioCierre = data['horarioCierre'] as String?;

    // Validar primer turno
    if (horarioApertura == null ||
        horarioCierre == null ||
        horarioApertura.isEmpty ||
        horarioCierre.isEmpty ||
        horarioApertura == '--:--' ||
        horarioCierre == '--:--') {
      return "Horarios no configurados";
    }

    final tieneDobleTurno = data['tieneDobleTurno'] ?? false;

    // Formatear primer turno
    final firstShift = "$horarioApertura a $horarioCierre";

    // Si no tiene doble turno, retornar solo el primer turno
    if (!tieneDobleTurno) {
      return firstShift;
    }

    // Verificar segundo turno
    final horarioApertura2 = data['horarioApertura2'] as String?;
    final horarioCierre2 = data['horarioCierre2'] as String?;

    if (horarioApertura2 == null ||
        horarioCierre2 == null ||
        horarioApertura2.isEmpty ||
        horarioCierre2.isEmpty ||
        horarioApertura2 == '--:--' ||
        horarioCierre2 == '--:--') {
      // Si tiene doble turno activado pero no configurado, mostrar solo el primero
      return firstShift;
    }

    // Formatear segundo turno
    final secondShift = "$horarioApertura2 a $horarioCierre2";

    // Retornar ambos turnos separados por "y"
    return "$firstShift y $secondShift";
  }

  /// Obtiene el estado de apertura formateado para mostrar al cliente
  ///
  /// Combina `isVenueOpen` y `getFormattedHours` para mostrar un mensaje completo
  ///
  /// Retorna un string como:
  /// - "Abierto ahora (09:00 a 15:00)"
  /// - "Cerrado ahora (09:00 a 15:00 y 19:00 a 00:00)"
  static String getVenueStatusMessage(Map<String, dynamic> data) {
    final isOpen = isVenueOpen(data);
    final hours = getFormattedHours(data);

    if (isOpen) {
      return "Abierto ahora ($hours)";
    } else {
      return "Cerrado ahora ($hours)";
    }
  }
}
