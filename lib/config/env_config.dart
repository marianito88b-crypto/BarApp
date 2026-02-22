/// Configuración de variables de entorno para BarApp.
///
/// Las claves se inyectan en tiempo de compilación mediante --dart-define.
/// Ejemplo de build:
///   flutter build web --dart-define-from-file=dart_defines.json
///
/// Usa dart_defines.json.example como plantilla para crear dart_defines.json
/// (este último está en .gitignore y no debe subirse al repositorio).
library;

/// Clave API de Google Maps (Web, Android, iOS).
String get googleMapsApiKey =>
    const String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );

/// Indica si las claves de entorno están configuradas.
bool get isEnvConfigured => googleMapsApiKey.isNotEmpty;
