@echo off
chcp 65001 >nul
title Detener Sistema de Stock

echo Cerrando scripts de Windows (para que no vuelva a abrir el sistema)...
taskkill /IM wscript.exe /F >nul 2>&1

echo Cerrando procesos del servidor (puerto 3001)...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "$conns = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue; ^
   if ($conns) { $conns | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }; Write-Host 'Servidor detenido.' } ^
   else { Write-Host 'No habia servidor escuchando en el puerto 3001.' }"

echo Cerrando tunel...
taskkill /IM ngrok.exe /F >nul 2>&1
taskkill /IM cloudflared.exe /F >nul 2>&1
echo Tunel detenido (si estaba corriendo).
echo.
echo Cerra ESTA ventana negra. Mientras este abierta no se puede borrar scripts.
echo Despues subi una carpeta en el Explorador (no te quedes dentro de scripts)
echo y ahi si podes borrar o pegar archivos.
echo No borres tunel-config.txt (token y dominio de ngrok).
echo.
cd /d "%TEMP%"
timeout /t 8
exit /b 0
