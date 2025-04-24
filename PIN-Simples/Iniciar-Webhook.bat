@echo off
color 0A
title Iniciar Servidor Webhook

echo =====================================================
echo    INICIAR SERVIDOR WEBHOOK
echo =====================================================
echo.
echo Este script ira iniciar o servidor webhook na porta 8081.
echo.
echo Pressione qualquer tecla para iniciar...
pause > nul

echo.
echo Iniciando servidor webhook...
echo.

REM Iniciar o servidor webhook
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\WebhookServer.ps1"

echo.
echo Servidor webhook encerrado.
echo.
echo =====================================================
echo.
pause
