@echo off
echo Iniciando teste de automacao...
echo.
powershell -ExecutionPolicy Bypass -File test-automation.ps1
echo.
echo Pressione qualquer tecla para sair...
pause > nul
