@echo off
color 0A
echo =====================================================
echo    PIN AUTOMACAO - EXECUCAO IMEDIATA
echo =====================================================
echo.
echo Iniciando servidor webhook...
echo Este aplicativo ira aguardar requisicoes e executar
echo a automacao IMEDIATAMENTE quando receber dados.
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

echo =====================================================
echo SERVIDOR INICIADO NA PORTA 8080
echo -----------------------------------------------------
echo Acesse https://pin-v2-six.vercel.app/
echo Preencha o PIN e Nome e clique em Enviar
echo -----------------------------------------------------
echo A automacao sera executada imediatamente!
echo -----------------------------------------------------
echo Pressione Ctrl+C para interromper.
echo =====================================================
echo.

REM Executar o script PowerShell
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\WebhookServer.ps1"

pause
