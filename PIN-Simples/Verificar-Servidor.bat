@echo off
color 0A
title Verificar Servidor Webhook

echo =====================================================
echo    VERIFICAR SERVIDOR WEBHOOK
echo =====================================================
echo.
echo Verificando se o servidor webhook esta rodando...
echo.

REM Verificar se a porta 8080 está em uso
netstat -ano | findstr :8080 > nul
if %ERRORLEVEL% equ 0 (
    echo SERVIDOR ATIVO!
    echo O servidor webhook esta rodando na porta 8080.
    echo.
    echo Para testar, acesse: http://localhost:8080
    echo.
    echo Para usar:
    echo 1. Acesse o formulario web: https://pin-v2-six.vercel.app/
    echo 2. Preencha o PIN e Nome e clique em Enviar
    echo 3. A automacao sera executada imediatamente neste computador
) else (
    color 0C
    echo SERVIDOR INATIVO!
    echo O servidor webhook NAO esta rodando.
    echo.
    echo Para iniciar o servidor, execute um dos seguintes arquivos:
    echo - PIN-Servidor.bat (mostra a janela do servidor)
    echo - PIN-Invisivel.vbs (inicia o servidor em segundo plano)
)

echo.
echo =====================================================
echo.
pause
