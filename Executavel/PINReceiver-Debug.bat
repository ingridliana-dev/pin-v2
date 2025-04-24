@echo off
title Receptor de PIN - Modo Debug
color 0A

echo =====================================================
echo    RECEPTOR DE PIN - MODO DEBUG
echo =====================================================
echo.
echo Este modo mostra logs detalhados para diagnostico.
echo.
echo Verificando requisitos...

:: Verificar se o Node.js está instalado
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo ERRO: Node.js nao encontrado!
    echo Por favor, instale o Node.js de https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo Node.js encontrado: 
node --version

:: Verificar se o Puppeteer está instalado
node -e "try { require('puppeteer'); console.log('Puppeteer instalado com sucesso.'); } catch(e) { console.error('Puppeteer nao instalado: ' + e.message); process.exit(1); }" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    color 0E
    echo AVISO: Puppeteer nao encontrado. Tentando instalar...
    npm install puppeteer
) else (
    echo Puppeteer encontrado.
)

echo.
echo Iniciando aplicativo...
echo.
echo =====================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\PINReceiver.ps1"

echo.
echo =====================================================
echo Aplicativo encerrado.
echo Pressione qualquer tecla para sair...
pause > nul
