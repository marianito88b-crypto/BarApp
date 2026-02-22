#!/usr/bin/env dart
// Migración única: extrae claves de firebase_options.dart y genera dart_defines.json.
// Ejecutar ANTES de subir el repo a público: dart run tool/generate_dart_defines.dart
// Luego dart_defines.json (con tus claves) quedará local y en .gitignore.

import 'dart:convert';
import 'dart:io';

void main() {
  final optsFile = File('lib/firebase_options.dart');
  if (!optsFile.existsSync()) {
    stderr.writeln('No existe lib/firebase_options.dart');
    exit(1);
  }

  final content = optsFile.readAsStringSync();
  final maps = _extractMap(content);

  // Google Maps: preguntar o leer de index.html
  var mapsKey = '';
  final indexHtml = File('web/index.html');
  if (indexHtml.existsSync()) {
    final m = RegExp(r'key=([A-Za-z0-9_-]+)').firstMatch(indexHtml.readAsStringSync());
    if (m != null) mapsKey = m.group(1)!;
  }
  if (mapsKey.isEmpty) {
    stdout.write('Google Maps API Key: ');
    mapsKey = (stdin.readLineSync() ?? '').trim();
  }

  final output = <String, String>{
    'GOOGLE_MAPS_API_KEY': mapsKey,
    ...maps,
  };

  File('dart_defines.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(output),
  );
  stdout.writeln('✓ dart_defines.json generado.');
  stdout.writeln('  Para Android, añade a android/local.properties:');
  stdout.writeln('  maps.api.key=$mapsKey');
}

Map<String, String> _extractMap(String content) {
  final result = <String, String>{};
  final platformKeys = {
    'web': 'FIREBASE_WEB',
    'android': 'FIREBASE_ANDROID',
    'ios': 'FIREBASE_IOS',
    'macos': 'FIREBASE_MACOS',
    'windows': 'FIREBASE_WINDOWS',
  };

  for (final entry in platformKeys.entries) {
    final platform = entry.key;
    final prefix = entry.value;
    final block = RegExp(
      'static (?:const )?FirebaseOptions $platform = FirebaseOptions\\(([^)]+)\\)',
      dotAll: true,
    ).firstMatch(content);

    if (block == null) continue;

    final fieldMap = {
      'apiKey': '${prefix}_API_KEY',
      'appId': '${prefix}_APP_ID',
      'projectId': '${prefix}_PROJECT_ID',
      'authDomain': '${prefix}_AUTH_DOMAIN',
      'storageBucket': '${prefix}_STORAGE_BUCKET',
      'messagingSenderId': '${prefix}_MESSAGING_SENDER_ID',
      'androidClientId': '${prefix}_ANDROID_CLIENT_ID',
      'iosClientId': '${prefix}_IOS_CLIENT_ID',
      'iosBundleId': '${prefix}_BUNDLE_ID',
    };

    for (final f in fieldMap.entries) {
      final m = RegExp("${f.key}: '([^']*)'").firstMatch(block.group(1)!);
      if (m != null) result[f.value] = m.group(1)!;
    }
  }
  return result;
}
