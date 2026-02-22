# Configuración de claves sensibles

Para compilar y ejecutar BarApp necesitas configurar las claves (Firebase, Google Maps). Estas **nunca** se suben al repositorio.

## 1. Migración (una sola vez, si ya tienes el proyecto)

Si ya tenías el proyecto funcionando, ejecuta:

```bash
dart run tool/generate_dart_defines.dart
```

Esto generará `dart_defines.json` con tus claves actuales.

## 2. Configuración desde cero

### Paso A: dart_defines.json

1. Copia la plantilla:
   ```bash
   cp dart_defines.json.example dart_defines.json
   ```

2. Rellena las claves en `dart_defines.json`. Puedes obtenerlas de:
   - **Firebase**: [Firebase Console](https://console.firebase.google.com) → tu proyecto → Configuración
   - **Google Maps**: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### Paso B: Android (clave de Maps)

Añade a `android/local.properties`:

```properties
maps.api.key=TU_GOOGLE_MAPS_API_KEY
```

(El archivo `local.properties` ya existe con `sdk.dir`; añade la línea anterior.)

### Paso C: iOS / macOS

Las claves de Firebase para iOS y macOS se obtienen del `dart_defines.json`. No hace falta modificar archivos nativos adicionales.

## 3. Ejecución local

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## 4. Build para web

```bash
./deploy_web.sh
```

El script compila con `dart_defines.json` e inyecta la clave de Google Maps en el HTML.

## Archivos que NO se suben (están en .gitignore)

- `.env`
- `dart_defines.json`
- `key.properties`
- `local.properties` (contiene rutas locales y `maps.api.key`)
