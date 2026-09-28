@echo off
chcp 65001 >nul
title Actualizar Sistema de Stock

cd /d "%~dp0.."

where node >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Instala Node.js LTS desde https://nodejs.org
  pause
  exit /b 1
)

echo ========================================
echo  Actualizar Sistema de Stock
echo  Usa esto DESPUES de pegar codigo nuevo
echo  (sin pisar backend\.env ni la base)
echo ========================================
echo.

echo Instalando / actualizando dependencias del backend...
pushd backend
call npm install
if errorlevel 1 goto error
popd

echo.
echo Instalando / actualizando dependencias del frontend...
pushd frontend
call npm install
if errorlevel 1 goto error
popd

echo.
echo Compilando interfaz (frontend)...
pushd frontend
call npm run build
if errorlevel 1 goto error
popd

echo.
echo Cerrando el servidor anterior (sin ventanas extra) para aplicar el codigo nuevo...
powershell -NoProfile -WindowStyle Hidden -Command "Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }; Get-Process ngrok -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"

echo.
echo Listo. La interfaz nueva ya esta compilada.
echo Ahora abre el acceso directo "Sistema de Stock" (el servidor arranca solo, sin CMD).
echo.
echo Si no abre, ejecuta scripts\diagnosticar.bat y revisa servidor.log
echo.
pause
exit /b 0

:error
echo.
echo [ERROR] Fallo la actualizacion. Revisa el mensaje de arriba.
pause
exit /b 1
