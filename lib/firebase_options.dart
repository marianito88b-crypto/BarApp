// Configuración de Firebase - Claves desde --dart-define.
// Ejecuta: flutter run --dart-define-from-file=dart_defines.json
// Crea dart_defines.json copiando dart_defines.json.example y rellenando.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Lee claves desde --dart-define (dart_defines.json)
String _def(String key, [String fallback = '']) {
  // fromEnvironment requiere clave literal en tiempo de compilación
  switch (key) {
    case 'FIREBASE_WEB_API_KEY':
      return const String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');
    case 'FIREBASE_WEB_APP_ID':
      return const String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');
    case 'FIREBASE_WEB_PROJECT_ID':
      return const String.fromEnvironment('FIREBASE_WEB_PROJECT_ID', defaultValue: '');
    case 'FIREBASE_WEB_AUTH_DOMAIN':
      return const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN', defaultValue: '');
    case 'FIREBASE_WEB_STORAGE_BUCKET':
      return const String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET', defaultValue: '');
    case 'FIREBASE_WEB_MESSAGING_SENDER_ID':
      return const String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID', defaultValue: '');
    case 'FIREBASE_ANDROID_API_KEY':
      return const String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
    case 'FIREBASE_ANDROID_APP_ID':
      return const String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
    case 'FIREBASE_ANDROID_PROJECT_ID':
      return const String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID', defaultValue: '');
    case 'FIREBASE_ANDROID_STORAGE_BUCKET':
      return const String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET', defaultValue: '');
    case 'FIREBASE_ANDROID_MESSAGING_SENDER_ID':
      return const String.fromEnvironment('FIREBASE_ANDROID_MESSAGING_SENDER_ID', defaultValue: '');
    case 'FIREBASE_IOS_API_KEY':
      return const String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '');
    case 'FIREBASE_IOS_APP_ID':
      return const String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');
    case 'FIREBASE_IOS_PROJECT_ID':
      return const String.fromEnvironment('FIREBASE_IOS_PROJECT_ID', defaultValue: '');
    case 'FIREBASE_IOS_STORAGE_BUCKET':
      return const String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET', defaultValue: '');
    case 'FIREBASE_IOS_MESSAGING_SENDER_ID':
      return const String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID', defaultValue: '');
    case 'FIREBASE_IOS_ANDROID_CLIENT_ID':
      return const String.fromEnvironment('FIREBASE_IOS_ANDROID_CLIENT_ID', defaultValue: '');
    case 'FIREBASE_IOS_IOS_CLIENT_ID':
      return const String.fromEnvironment('FIREBASE_IOS_IOS_CLIENT_ID', defaultValue: '');
    case 'FIREBASE_IOS_BUNDLE_ID':
      return const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: '');
    case 'FIREBASE_MACOS_API_KEY':
      return const String.fromEnvironment('FIREBASE_MACOS_API_KEY', defaultValue: '');
    case 'FIREBASE_MACOS_APP_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_APP_ID', defaultValue: '');
    case 'FIREBASE_MACOS_PROJECT_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_PROJECT_ID', defaultValue: '');
    case 'FIREBASE_MACOS_STORAGE_BUCKET':
      return const String.fromEnvironment('FIREBASE_MACOS_STORAGE_BUCKET', defaultValue: '');
    case 'FIREBASE_MACOS_MESSAGING_SENDER_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_MESSAGING_SENDER_ID', defaultValue: '');
    case 'FIREBASE_MACOS_ANDROID_CLIENT_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_ANDROID_CLIENT_ID', defaultValue: '');
    case 'FIREBASE_MACOS_IOS_CLIENT_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_IOS_CLIENT_ID', defaultValue: '');
    case 'FIREBASE_MACOS_BUNDLE_ID':
      return const String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID', defaultValue: '');
    case 'FIREBASE_WINDOWS_API_KEY':
      return const String.fromEnvironment('FIREBASE_WINDOWS_API_KEY', defaultValue: '');
    case 'FIREBASE_WINDOWS_APP_ID':
      return const String.fromEnvironment('FIREBASE_WINDOWS_APP_ID', defaultValue: '');
    case 'FIREBASE_WINDOWS_PROJECT_ID':
      return const String.fromEnvironment('FIREBASE_WINDOWS_PROJECT_ID', defaultValue: '');
    case 'FIREBASE_WINDOWS_AUTH_DOMAIN':
      return const String.fromEnvironment('FIREBASE_WINDOWS_AUTH_DOMAIN', defaultValue: '');
    case 'FIREBASE_WINDOWS_STORAGE_BUCKET':
      return const String.fromEnvironment('FIREBASE_WINDOWS_STORAGE_BUCKET', defaultValue: '');
    case 'FIREBASE_WINDOWS_MESSAGING_SENDER_ID':
      return const String.fromEnvironment('FIREBASE_WINDOWS_MESSAGING_SENDER_ID', defaultValue: '');
    default:
      return fallback;
  }
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _def('FIREBASE_WEB_API_KEY'),
        appId: _def('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _def('FIREBASE_WEB_MESSAGING_SENDER_ID'),
        projectId: _def('FIREBASE_WEB_PROJECT_ID'),
        authDomain: _def('FIREBASE_WEB_AUTH_DOMAIN'),
        storageBucket: _def('FIREBASE_WEB_STORAGE_BUCKET'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _def('FIREBASE_ANDROID_API_KEY'),
        appId: _def('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _def('FIREBASE_ANDROID_MESSAGING_SENDER_ID'),
        projectId: _def('FIREBASE_ANDROID_PROJECT_ID'),
        storageBucket: _def('FIREBASE_ANDROID_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _def('FIREBASE_IOS_API_KEY'),
        appId: _def('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _def('FIREBASE_IOS_MESSAGING_SENDER_ID'),
        projectId: _def('FIREBASE_IOS_PROJECT_ID'),
        storageBucket: _def('FIREBASE_IOS_STORAGE_BUCKET'),
        androidClientId: _def('FIREBASE_IOS_ANDROID_CLIENT_ID'),
        iosClientId: _def('FIREBASE_IOS_IOS_CLIENT_ID'),
        iosBundleId: _def('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _def('FIREBASE_MACOS_API_KEY'),
        appId: _def('FIREBASE_MACOS_APP_ID'),
        messagingSenderId: _def('FIREBASE_MACOS_MESSAGING_SENDER_ID'),
        projectId: _def('FIREBASE_MACOS_PROJECT_ID'),
        storageBucket: _def('FIREBASE_MACOS_STORAGE_BUCKET'),
        androidClientId: _def('FIREBASE_MACOS_ANDROID_CLIENT_ID'),
        iosClientId: _def('FIREBASE_MACOS_IOS_CLIENT_ID'),
        iosBundleId: _def('FIREBASE_MACOS_BUNDLE_ID'),
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _def('FIREBASE_WINDOWS_API_KEY'),
        appId: _def('FIREBASE_WINDOWS_APP_ID'),
        messagingSenderId: _def('FIREBASE_WINDOWS_MESSAGING_SENDER_ID'),
        projectId: _def('FIREBASE_WINDOWS_PROJECT_ID'),
        authDomain: _def('FIREBASE_WINDOWS_AUTH_DOMAIN'),
        storageBucket: _def('FIREBASE_WINDOWS_STORAGE_BUCKET'),
      );
}
