@echo off
REM =============================================================================
REM deploy_web.bat - Script de despliegue para BarApp Web (Firebase Hosting)
REM =============================================================================
REM Ejecuta la secuencia correcta de build para evitar errores de iconos,
REM caché 206 y MIME type en fuentes.
REM =============================================================================

echo [1/5] Limpiando proyecto...
call flutter clean

echo.
echo [2/5] Obteniendo dependencias...
call flutter pub get

echo.
echo [3/5] Compilando para web (release, sin tree-shake de iconos)...
call flutter build web --release --no-tree-shake-icons

echo.
echo [4/5] Eliminando flutter_service_worker.js para evitar error 206...
if exist "build\web\flutter_service_worker.js" (
  del /f "build\web\flutter_service_worker.js"
  echo    OK flutter_service_worker.js eliminado
) else (
  echo    No encontrado - puede estar en otra ruta
)

echo.
echo [5/5] Desplegando a Firebase Hosting...
call firebase deploy --only hosting

echo.
echo Despliegue completado!
echo.
pause
