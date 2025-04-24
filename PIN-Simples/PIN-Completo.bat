@echo off
color 0A
title PIN Automacao Completa

echo =====================================================
echo    PIN AUTOMACAO COMPLETA
echo =====================================================
echo.
echo Iniciando sistema completo de automacao...
echo Este aplicativo ira:
echo  1. Iniciar o servidor webhook para receber dados
echo  2. Abrir o formulario web no navegador
echo.
echo Quando voce preencher o formulario e clicar em Enviar,
echo a automacao sera executada imediatamente!
echo.

REM Verificar se o PowerShell está disponível
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    color 0C
    echo ERRO: PowerShell nao encontrado.
    echo Por favor, instale o PowerShell para continuar.
    pause
    exit /b 1
)

REM Verificar se o Node.js está disponível
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    color 0C
    echo ERRO: Node.js nao encontrado.
    echo Por favor, instale o Node.js para continuar.
    pause
    exit /b 1
) else (
    echo Node.js encontrado:
    node --version
    echo.
)

REM Verificar dependências
echo Verificando dependencias...
cd scripts
call npm install puppeteer
if %ERRORLEVEL% neq 0 (
    color 0C
    echo ERRO: Falha ao instalar dependencias.
    pause
    exit /b 1
)
echo Puppeteer instalado com sucesso.
echo.

REM Iniciar o servidor webhook em segundo plano
echo Iniciando servidor webhook...
start /min powershell -ExecutionPolicy Bypass -File "%~dp0scripts\WebhookServer.ps1"
echo Servidor webhook iniciado com sucesso!
echo.

REM Aguardar um pouco para garantir que o servidor iniciou
timeout /t 3 /nobreak > nul

REM Abrir o formulário web no navegador padrão
echo Abrindo formulario web no navegador...
start https://pin-v2-six.vercel.app/
echo.

echo =====================================================
echo SISTEMA COMPLETO INICIADO COM SUCESSO!
echo -----------------------------------------------------
echo O servidor webhook esta rodando em: http://localhost:8080
echo O formulario web foi aberto no seu navegador
echo -----------------------------------------------------
echo Para usar:
echo 1. Preencha o PIN e Nome no formulario
echo 2. Clique em Enviar
echo 3. A automacao sera executada imediatamente!
echo -----------------------------------------------------
echo Mantenha esta janela aberta enquanto estiver usando o sistema.
echo Pressione Ctrl+C para encerrar o sistema.
echo =====================================================
echo.

REM Manter a janela aberta
echo Pressione Ctrl+C para encerrar o sistema...
pause > nul
