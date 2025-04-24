@echo off
echo Convertendo script PowerShell para executavel...

:: Criar pasta para o executavel
mkdir Executavel 2>nul

:: Verificar se o modulo PS2EXE esta instalado
powershell -Command "if (-not (Get-Module -ListAvailable -Name PS2EXE)) { Write-Host 'Instalando modulo PS2EXE...'; Install-Module -Name PS2EXE -Scope CurrentUser -Force }"

:: Converter o script para executavel
powershell -Command "Import-Module PS2EXE; Invoke-PS2EXE -InputFile 'PINReceiver.ps1' -OutputFile 'Executavel\PINReceiver.exe' -NoConsole -IconFile 'Executavel\app.ico' -Title 'Receptor de PIN' -Version '1.0.0' -Description 'Aplicativo para receber dados de PIN do formulario web'"

:: Verificar se a conversao foi bem-sucedida
if %ERRORLEVEL% neq 0 (
    echo Erro na conversao.
    exit /b 1
)

echo.
echo Conversao concluida com sucesso!
echo O executavel esta disponivel em Executavel\PINReceiver.exe
echo.

pause
