@echo off
echo =====================================================
echo    PIN AUTOMACAO - WEBHOOK SERVER
echo =====================================================
echo.
echo Iniciando servidor webhook...
echo Este aplicativo ira aguardar requisicoes e executar
echo a automacao imediatamente quando receber dados.
echo.

REM Verificar se o PowerShell está disponível
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERRO: PowerShell nao encontrado.
    echo Por favor, instale o PowerShell para continuar.
    pause
    exit /b 1
)

REM Verificar se o Node.js está disponível
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
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
    echo ERRO: Falha ao instalar dependencias.
    pause
    exit /b 1
)
echo Puppeteer instalado com sucesso.
echo.

echo =====================================================
echo Iniciando servidor webhook na porta 8080...
echo Pressione Ctrl+C para interromper.
echo.

REM Executar o script PowerShell
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\WebhookServer.ps1"

pause
