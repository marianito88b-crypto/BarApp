# Despliegue Web - Firebase Hosting (BarApp)

Guía para un despliegue 10/10 en Firebase Hosting, evitando errores comunes de iconos, fuentes y caché.

---

## Errores comunes y soluciones

### 1. Iconos no se muestran (Tree-shaking)

**Síntoma:** Iconos de FontAwesome, MaterialIcons o el sello de BarPoints aparecen como cuadrados vacíos.

**Causa:** Flutter por defecto hace *tree-shaking* de fuentes de iconos y elimina los glifos que cree que no se usan. El análisis estático no detecta todos los iconos (especialmente los usados dinámicamente o en paquetes).

**Solución:**
```bash
flutter build web --release --no-tree-shake-icons
```

El flag `--no-tree-shake-icons` evita que se poden las fuentes de iconos.

---

### 2. Error de fuentes Noto / MIME type

**Síntoma:** Consola del navegador muestra errores como:
- `Resource interpreted as Font but transferred with MIME type application/octet-stream`
- Warnings sobre fuentes Noto faltantes

**Causas:**
- Headers incorrectos en los archivos de fuentes (.otf, .ttf, .woff2)
- Tree-shaking excesivo de fuentes de texto

**Soluciones aplicadas:**
1. **firebase.json:** Reglas de `headers` para fuentes con `Content-Type` correcto.
2. **Build:** `--no-tree-shake-icons` también ayuda con fuentes de iconos vinculadas.

---

### 3. Error 206 (Partial Content) con Service Worker

**Síntoma:** Tras actualizar la app, algunos usuarios ven fallos de carga o pantallas en blanco.

**Causa:** El `flutter_service_worker.js` cachea assets. Si la versión cambia y el SW sirve contenido viejo o respuestas parciales, puede generar errores 206.

**Solución:** Borrar `build/web/flutter_service_worker.js` antes de desplegar. La app funcionará sin caché offline pero sin problemas de actualización.

---

## Script de despliegue recomendado

Usar el script `deploy_web.sh` en la raíz del proyecto:

```bash
chmod +x deploy_web.sh
./deploy_web.sh
```

O ejecutar manualmente:

```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
rm -f build/web/flutter_service_worker.js   # Opcional: evita error 206
firebase deploy --only hosting
```

---

## Verificaciones previas al despliegue

| Elemento | Estado |
|----------|--------|
| `web/index.html` | Google Maps con `async defer`, `window.flutterConfiguration` |
| `pubspec.yaml` | `uses-material-design: true` |
| `firebase.json` | `public: build/web`, rewrites SPA, headers para fuentes |
| Build | Con `--no-tree-shake-icons` |

---

## Resultado esperado

Tras aplicar los cambios:
- ✅ Todos los iconos visibles (sello BarPoints, botón copiar, etc.)
- ✅ Mapa cargando sin warnings
- ✅ Sin errores de MIME type en consola
- ✅ Despliegue sin errores 206
