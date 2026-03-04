#!/usr/bin/env bash
# DEPRECADO: La clave de Google Maps se inyecta dinámicamente desde main.dart
# (EnvironmentConfig + maps_script_loader_web). Ya no se usa este script en deploy.
#
# Histórico: Reemplazaba __GOOGLE_MAPS_API_KEY__ en build/web/index.html.
set -e

MAPS_KEY="${GOOGLE_MAPS_API_KEY:-}"
if [ -z "$MAPS_KEY" ] && [ -f "dart_defines.json" ]; then
  MAPS_KEY=$(grep "GOOGLE_MAPS_API_KEY" dart_defines.json | sed 's/.*"GOOGLE_MAPS_API_KEY"[^"]*"\([^"]*\)".*/\1/')
fi

if [ -z "$MAPS_KEY" ]; then
  echo "⚠️  No se encontró GOOGLE_MAPS_API_KEY. Usa dart_defines.json o exporta GOOGLE_MAPS_API_KEY."
  exit 1
fi

INDEX="build/web/index.html"
if [ ! -f "$INDEX" ]; then
  echo "⚠️  No existe $INDEX. Ejecuta 'flutter build web' primero."
  exit 1
fi

if sed -i.bak "s|__GOOGLE_MAPS_API_KEY__|$MAPS_KEY|g" "$INDEX" 2>/dev/null || \
   sed -i '' "s|__GOOGLE_MAPS_API_KEY__|$MAPS_KEY|g" "$INDEX" 2>/dev/null; then
  rm -f "${INDEX}.bak" 2>/dev/null || true
  echo "✓ Clave de Google Maps inyectada en index.html"
else
  echo "⚠️  No se pudo reemplazar. Verifica que index.html contenga __GOOGLE_MAPS_API_KEY__"
  exit 1
fi
