@echo off
color 0A
title Iniciar Ngrok para Webhook

echo =====================================================
echo    INICIAR NGROK PARA WEBHOOK
echo =====================================================
echo.
echo Este script ira iniciar o ngrok para criar um tunel
echo para o servidor webhook local.
echo.
echo IMPORTANTE: Voce precisa baixar o ngrok manualmente:
echo 1. Acesse https://ngrok.com/download
echo 2. Baixe a versao para Windows
echo 3. Extraia o arquivo ngrok.exe para a pasta:
echo    PIN-Simples\tools
echo.
echo Pressione qualquer tecla quando tiver baixado o ngrok...
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
echo =====================================================
echo NGROK INICIADO COM SUCESSO!
echo =====================================================
echo.
echo URL do tunel: %NGROK_URL%
echo.
echo IMPORTANTE: Voce precisa atualizar a API para usar esta URL.
echo.
echo 1. Edite o arquivo pages/api/data.js
echo 2. Substitua a URL do webhook por: %NGROK_URL%
echo 3. Faca o commit e push das alteracoes
echo.
echo Mantenha esta janela aberta enquanto estiver usando o sistema.
echo O tunel sera fechado quando voce fechar esta janela.
echo.
echo =====================================================
echo.
echo Pressione Ctrl+C para encerrar o ngrok...
pause > nul
