@echo off
echo Iniciando Receptor de PIN...
echo.
echo Este console mostrará mensagens de log e erros.
echo Não feche esta janela enquanto o aplicativo estiver em execução.
echo.
echo Pressione Ctrl+C para encerrar o aplicativo.
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\..\PINReceiver.ps1"
