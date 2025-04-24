@echo off
color 0A
title Verificar Porta 8080

echo =====================================================
echo    VERIFICAR PORTA 8080
echo =====================================================
echo.
echo Este script ira verificar se a porta 8080 esta aberta
echo e acessivel.
echo.

REM Verificar se a porta 8080 está em uso
netstat -ano | findstr :8080
if %ERRORLEVEL% equ 0 (
    echo.
    echo A porta 8080 esta em uso. Isso e bom!
    echo O servidor webhook deve estar rodando.
    echo.
    
    REM Verificar se podemos acessar o servidor
    echo Tentando acessar o servidor...
    curl -s -o nul -w "%%{http_code}" http://localhost:8080
    if %ERRORLEVEL% equ 0 (
        echo.
        echo Conseguimos acessar o servidor! Tudo parece estar funcionando.
    ) else (
        color 0E
        echo.
        echo Aviso: A porta esta em uso, mas nao conseguimos acessar o servidor.
        echo Isso pode indicar um problema de firewall ou permissoes.
    )
) else (
    color 0C
    echo.
    echo A porta 8080 NAO esta em uso!
    echo O servidor webhook provavelmente nao esta rodando.
    echo.
    echo Execute o arquivo PIN-Servidor.bat ou PIN-Invisivel.vbs
    echo para iniciar o servidor webhook.
)

echo.
echo =====================================================
echo.
pause
