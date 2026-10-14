@echo off
chcp 65001 >nul
title Cerrar para actualizar archivos

echo.
echo Cierra el sistema para poder copiar o borrar la carpeta scripts.
echo No borres tunel-config.txt (ahi esta el token y el dominio de ngrok).
echo.

echo Cerrando scripts de Windows (wscript)...
taskkill /IM wscript.exe /F >nul 2>&1

echo Cerrando servidor (puerto 3001)...
powershell -NoProfile -WindowStyle Hidden -Command "Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }"

echo Cerrando tunel...
taskkill /IM ngrok.exe /F >nul 2>&1
taskkill /IM cloudflared.exe /F >nul 2>&1

echo.
echo Cerra ESTA ventana negra. Mientras este abierta no se puede borrar scripts.
echo En el Explorador subi a la carpeta del sistema (no te quedes dentro de scripts).
echo Conserva: scripts\tunel-config.txt
echo.
echo Cuando termines de copiar, abre el acceso directo Sistema de Stock.
echo.
cd /d "%TEMP%"
timeout /t 8
exit /b 0
