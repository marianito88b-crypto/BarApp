// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Inyecta dinámicamente el script de Google Maps en web.
/// Usa la clave desde EnvironmentConfig (--dart-define).
/// Solo se ejecuta si [apiKey] no está vacía para evitar InvalidKey.
void injectGoogleMapsScript(String apiKey) {
  if (apiKey.isEmpty) return;

  // Evitar inyectar dos veces
  if (html.document.querySelector('script[src*="maps.googleapis.com"]') != null) {
    return;
  }

  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..async = true
    ..defer = true;

  html.document.head?.append(script);
}
