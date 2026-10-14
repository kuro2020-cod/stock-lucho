@echo off
chcp 65001 >nul
title Inicio automatico - Sistema de Stock

cd /d "%~dp0"
echo.
echo Configura el arranque solo: al encender la PC se levantan
echo el servidor y el tunel ngrok (acceso desde afuera), sin abrir
echo el navegador ni ventanas negras.
echo.

if not exist "%~dp0asegurar-inicio.vbs" (
  echo [ERROR] Falta scripts\asegurar-inicio.vbs
  pause
  exit /b 1
)

cscript //nologo "%~dp0asegurar-inicio.vbs"
if errorlevel 1 (
  echo [ERROR] No se pudo registrar el inicio automatico.
  echo Proba clic derecho - Ejecutar como administrador.
  pause
  exit /b 1
)

call "%~dp0crear-acceso-directo.bat" /nopause

echo.
echo ========================================
echo Listo.
echo  1. Al prender la PC, el sistema y ngrok arrancan solos
echo     (espera unos segundos: PostgreSQL e internet).
echo  2. El icono "Sistema de Stock" solo abre el navegador.
echo  3. Si ngrok se cae, se reintenta solo cada 5 minutos.
echo ========================================
echo.
echo Para detener: scripts\detener-stock.bat
echo Para quitar el inicio automatico:
echo   schtasks /Delete /TN SistemaStock /F
echo.
pause
