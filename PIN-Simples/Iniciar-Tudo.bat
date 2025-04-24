@echo off
color 0A
title Iniciar Sistema Completo

echo =====================================================
echo    INICIAR SISTEMA COMPLETO
echo =====================================================
echo.
echo Este script ira iniciar todo o sistema:
echo 1. Servidor webhook
echo 2. Tunel ngrok
echo.
echo IMPORTANTE: Voce precisa ter baixado o ngrok primeiro!
echo.
echo Pressione qualquer tecla para continuar...
pause > nul

REM Verificar se o ngrok existe
if not exist "PIN-Simples\tools\ngrok.exe" (
    color 0C
    echo.
    echo ERRO: ngrok.exe nao encontrado!
    echo Por favor, baixe o ngrok e extraia para a pasta PIN-Simples\tools
    echo.
    echo 1. Acesse https://ngrok.com/download
    echo 2. Baixe a versao para Windows
    echo 3. Extraia o arquivo ngrok.exe para a pasta PIN-Simples\tools
    echo.
    pause
    exit /b 1
)

echo.
echo Iniciando ngrok...
echo.

REM Iniciar o ngrok para a porta 8081
start "Ngrok Tunnel" /min PIN-Simples\tools\ngrok.exe http 8081

REM Aguardar um pouco para o ngrok iniciar
timeout /t 5 /nobreak > nul

REM Obter a URL do ngrok
echo Obtendo URL do tunel...
powershell -Command "Invoke-WebRequest -Uri http://localhost:4040/api/tunnels -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty tunnels | Where-Object {$_.proto -eq 'https'} | Select-Object -ExpandProperty public_url" > PIN-Simples\tools\ngrok_url.txt

REM Ler a URL do arquivo
set /p NGROK_URL=<PIN-Simples\tools\ngrok_url.txt

echo.
echo URL do ngrok: %NGROK_URL%
echo.
echo IMPORTANTE: Voce precisa atualizar a API para usar esta URL.
echo Execute o script Atualizar-API.bat em outra janela.
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
