# Script para ler os logs da automação
$appDataFolder = [System.IO.Path]::Combine($env:APPDATA, "PINReceiverApp")
$logFile = [System.IO.Path]::Combine($appDataFolder, "automation-log.txt")
$errorLogFile = [System.IO.Path]::Combine($appDataFolder, "automation-log.txt.error")
$puppeteerLogFile = [System.IO.Path]::Combine($appDataFolder, "puppeteer-debug.log")

Write-Host "Verificando logs em: $appDataFolder" -ForegroundColor Cyan

if (Test-Path $logFile) {
    Write-Host "`nConteúdo do log principal:" -ForegroundColor Green
    Get-Content $logFile | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
} else {
    Write-Host "Arquivo de log principal não encontrado: $logFile" -ForegroundColor Yellow
}

if (Test-Path $errorLogFile) {
    Write-Host "`nConteúdo do log de erro:" -ForegroundColor Red
    Get-Content $errorLogFile | ForEach-Object { Write-Host $_ -ForegroundColor Red }
} else {
    Write-Host "Arquivo de log de erro não encontrado: $errorLogFile" -ForegroundColor Yellow
}

if (Test-Path $puppeteerLogFile) {
    Write-Host "`nConteúdo do log do Puppeteer:" -ForegroundColor Magenta
    Get-Content $puppeteerLogFile | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
} else {
    Write-Host "Arquivo de log do Puppeteer não encontrado: $puppeteerLogFile" -ForegroundColor Yellow
}

Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
