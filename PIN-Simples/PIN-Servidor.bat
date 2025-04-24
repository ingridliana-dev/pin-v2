@echo off
color 0A
title PIN Automacao - Servidor

echo =====================================================
echo    PIN AUTOMACAO - SERVIDOR
echo =====================================================
echo.
echo Iniciando servidor de automacao...
echo Este aplicativo ira aguardar dados do formulario web
echo e executar a automacao imediatamente quando receber.
echo.
echo O formulario pode ser preenchido por qualquer pessoa em:
echo https://pin-v2-six.vercel.app/
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

REM Iniciar o servidor webhook em segundo plano (invisível)
echo Iniciando servidor webhook em segundo plano...
start /min powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0scripts\WebhookServer.ps1"
echo Servidor webhook iniciado com sucesso!
echo.

echo =====================================================
echo SERVIDOR INICIADO COM SUCESSO!
echo -----------------------------------------------------
echo O servidor esta rodando em: http://localhost:8080
echo -----------------------------------------------------
echo Para usar:
echo 1. Qualquer pessoa pode acessar: https://pin-v2-six.vercel.app/
echo 2. Preencher o PIN e Nome no formulario
echo 3. Clicar em Enviar
echo 4. A automacao sera executada imediatamente neste computador!
echo -----------------------------------------------------
echo Mantenha esta janela aberta enquanto estiver usando o sistema.
echo Pressione Ctrl+C para encerrar o sistema.
echo =====================================================
echo.

REM Manter a janela aberta
echo Pressione Ctrl+C para encerrar o sistema...
pause > nul
