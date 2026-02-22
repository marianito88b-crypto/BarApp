#!/usr/bin/env bash
# =============================================================================
# deploy_web.sh - Script de despliegue para BarApp Web (Firebase Hosting)
# =============================================================================
# Requisito: dart_defines.json con claves (copia dart_defines.json.example)
# =============================================================================

set -e

if [ ! -f "dart_defines.json" ]; then
  echo "⚠️  Crea dart_defines.json (copia dart_defines.json.example y rellena las claves)"
  exit 1
fi

echo "🧹 [1/6] Limpiando proyecto..."
flutter clean

echo ""
echo "📦 [2/6] Obteniendo dependencias..."
flutter pub get

echo ""
echo "🏗️  [3/6] Compilando para web (con dart_defines.json)..."
flutter build web --release --no-tree-shake-icons --dart-define-from-file=dart_defines.json

echo ""
echo "🗺️  [4/6] Inyectando clave de Google Maps..."
bash tool/inject_maps_key.sh

echo ""
echo "🗑️  [5/6] Eliminando flutter_service_worker.js para evitar error 206..."
SW_PATH="build/web/flutter_service_worker.js"
if [ -f "$SW_PATH" ]; then
  rm -f "$SW_PATH"
  echo "   ✓ flutter_service_worker.js eliminado"
else
  echo "   ⚠ No encontrado (puede estar en otra ruta en tu versión de Flutter)"
fi

echo ""
echo "🚀 [6/6] Desplegando a Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ ¡Despliegue completado!"
echo ""
echo "Nota: La app funcionará sin Service Worker (sin caché offline)."
echo "      Esto evita el error 206 en actualizaciones."
echo ""
