@echo off
title PIN Automacao - Webhook
color 0A

echo =====================================================
echo    PIN AUTOMACAO - WEBHOOK
echo =====================================================
echo.
echo Iniciando servico de automacao...
echo Este aplicativo ira monitorar novos dados e executar
echo a automacao automaticamente quando receber dados.
echo.

:: Verificar se o Node.js está instalado
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo ERRO: Node.js nao encontrado!
    echo.
    echo Este aplicativo requer Node.js para funcionar.
    echo Por favor, instale o Node.js de https://nodejs.org/
    echo.
    echo Pressione qualquer tecla para sair...
    pause > nul
    exit /b 1
)

echo Node.js encontrado:
node --version
echo.

:: Verificar se o Puppeteer está instalado
cd "%~dp0scripts"
echo Verificando dependencias...
node -e "try { require('puppeteer'); console.log('Puppeteer instalado com sucesso.'); } catch(e) { console.error('Puppeteer nao instalado: ' + e.message); process.exit(1); }" >nul 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo Puppeteer nao encontrado. Instalando...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        color 0C
        echo ERRO: Falha ao instalar o Puppeteer.
        echo.
        pause
        exit /b 1
    )
) else (
    echo Puppeteer encontrado.
)

:: Voltar para o diretório original
cd "%~dp0"

echo.
echo =====================================================
echo Monitorando novos dados...
echo Pressione Ctrl+C para interromper.
echo.

:LOOP
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\PINReceiver.ps1"
echo.
echo Aguardando 30 segundos antes da proxima verificacao...
timeout /t 30 /nobreak > nul
goto LOOP
