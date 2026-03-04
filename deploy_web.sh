#!/usr/bin/env bash
# =============================================================================
# deploy_web.sh - Script de despliegue para BarApp Web (Firebase Hosting)
# =============================================================================
# Requisito: dart_defines.json con claves (copia dart_defines.json.example)
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 0. Validar dart_defines.json
if [ ! -f "dart_defines.json" ]; then
  echo -e "${RED}⚠️  Falta dart_defines.json${NC}"
  echo "Copia dart_defines.json.example y rellena las claves."
  exit 1
fi

# Validar que las claves no estén vacías
if ! grep -q '"FIREBASE_WEB_API_KEY"' dart_defines.json || \
   grep -q '"FIREBASE_WEB_API_KEY": ""' dart_defines.json; then
  echo -e "${RED}⚠️  FIREBASE_WEB_API_KEY vacío o ausente en dart_defines.json${NC}"
  exit 1
fi

echo -e "${YELLOW}🧹 [1/5] Limpiando build anterior...${NC}"
rm -rf build/web

echo ""
echo -e "${YELLOW}📦 [2/5] Obteniendo dependencias...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}🏗️  [3/5] Compilando para web (release + dart_defines)...${NC}"
flutter build web --release \
  --dart-define-from-file=dart_defines.json \
  --no-wasm-dry-run

# Validar que el build generó los archivos
if [ ! -f "build/web/main.dart.js" ]; then
  echo -e "${RED}❌ Build falló: build/web/main.dart.js no existe${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}🔍 [4/5] Verificando build...${NC}"
FILE_COUNT=$(find build/web -type f | wc -l | tr -d ' ')
JS_SIZE=$(du -sh build/web/main.dart.js | awk '{print $1}')
echo -e "   ${GREEN}✓${NC} Archivos generados: $FILE_COUNT"
echo -e "   ${GREEN}✓${NC} main.dart.js: $JS_SIZE"

echo ""
echo -e "${YELLOW}🚀 [5/5] Desplegando a Firebase Hosting...${NC}"
firebase deploy --only hosting

echo ""
echo -e "${GREEN}✅ Deploy exitoso!${NC}"
echo -e "   URL: https://barapp-social.web.app"
echo ""
