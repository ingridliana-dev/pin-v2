@echo off
color 0C
title Parar Servidor Webhook

echo =====================================================
echo    PARAR SERVIDOR WEBHOOK
echo =====================================================
echo.
echo Parando o servidor webhook...
echo.

REM Encontrar e encerrar processos do PowerShell que estão executando o WebhookServer.ps1
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq powershell.exe" /fo csv ^| findstr /i "powershell"') do (
    wmic process where "ProcessId=%%~a" get CommandLine | findstr /i "WebhookServer.ps1" > nul
    if not errorlevel 1 (
        echo Encerrando processo PowerShell (PID: %%~a)
        taskkill /F /PID %%~a
    )
)

REM Verificar se a porta 8080 ainda está em uso
netstat -ano | findstr :8080 > nul
if %ERRORLEVEL% equ 0 (
    echo.
    echo Encontrados processos usando a porta 8080. Tentando encerrar...
    
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr :8080') do (
        echo Encerrando processo com PID: %%p
        taskkill /F /PID %%p
    )
) else (
    echo Nenhum processo encontrado usando a porta 8080.
)

echo.
echo Servidor webhook parado com sucesso!
echo.
echo =====================================================
echo.
pause
