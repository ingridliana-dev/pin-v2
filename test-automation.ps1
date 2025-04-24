# Script de teste para verificar se a automação funciona corretamente
Write-Host "Iniciando teste de automação..." -ForegroundColor Green

# Obter o caminho do script de automação
$scriptDir = Split-Path -Parent $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Get-Location
}
$automationScript = Join-Path -Path $scriptDir -ChildPath "automation.js"

# Verificar se o script existe
if (-not (Test-Path $automationScript)) {
    Write-Host "ERRO: Script de automação não encontrado: $automationScript" -ForegroundColor Red
    exit 1
}
Write-Host "Script de automação encontrado: $automationScript" -ForegroundColor Green

# Verificar se o Node.js está instalado
try {
    $nodeVersion = node --version
    Write-Host "Node.js encontrado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "ERRO: Node.js não encontrado ou não está no PATH. Erro: $_" -ForegroundColor Red
    exit 1
}

# Verificar se o Puppeteer está instalado
try {
    $puppeteerCheck = node -e "try { require('puppeteer'); console.log('Puppeteer instalado'); } catch(e) { console.error('Puppeteer não instalado: ' + e.message); process.exit(1); }"
    Write-Host "Verificação do Puppeteer: $puppeteerCheck" -ForegroundColor Green
} catch {
    Write-Host "ERRO: Puppeteer não está instalado corretamente. Erro: $_" -ForegroundColor Red
    Write-Host "Tentando instalar o Puppeteer..." -ForegroundColor Yellow
    npm install puppeteer
}

# Definir parâmetros de teste
$pin = "1234"
$name = "Teste Direto"
$targetUrl = "https://localhost:47990/pin#PIN"

# Construir argumentos para o script
$argumentsString = "$automationScript --pin $pin --name `"$name`" --debug --target-url `"$targetUrl`""

Write-Host "Executando comando: node $argumentsString" -ForegroundColor Cyan

# Criar pasta para logs se não existir
$appDataFolder = Join-Path -Path $env:APPDATA -ChildPath "PINReceiverApp"
if (-not (Test-Path $appDataFolder)) {
    New-Item -Path $appDataFolder -ItemType Directory -Force | Out-Null
}

# Criar um arquivo de log para a saída do processo
$logFile = Join-Path -Path $appDataFolder -ChildPath "test-automation-log.txt"
Write-Host "Log será salvo em: $logFile" -ForegroundColor Yellow

# Executar o comando Node.js em uma nova janela para que seja visível
$process = Start-Process -FilePath "node" -ArgumentList $argumentsString -NoNewWindow:$false -PassThru -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.error"

Write-Host "Processo iniciado com ID: $($process.Id)" -ForegroundColor Green

# Aguardar um pouco para que o processo inicie
Write-Host "Aguardando 5 segundos para que o processo inicie..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Verificar se o processo ainda está em execução
if (-not $process.HasExited) {
    Write-Host "Automação em execução. Navegador deve estar visível." -ForegroundColor Green
    
    # Mostrar conteúdo do log até agora
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile -ErrorAction SilentlyContinue
        if ($logContent) {
            Write-Host "Conteúdo do log até agora:" -ForegroundColor Cyan
            foreach ($line in $logContent) {
                Write-Host "  LOG: $line" -ForegroundColor Gray
            }
        } else {
            Write-Host "Arquivo de log está vazio ou não pode ser lido." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Arquivo de log ainda não foi criado." -ForegroundColor Yellow
    }
    
    Write-Host "Aguardando a conclusão do processo..." -ForegroundColor Yellow
    $process.WaitForExit(60000) # Aguardar até 60 segundos
    
    if (-not $process.HasExited) {
        Write-Host "Processo ainda está em execução após 60 segundos. Continuando..." -ForegroundColor Yellow
    }
} else {
    # Se o processo já terminou, verificar o código de saída
    if ($process.ExitCode -ne 0) {
        Write-Host "Processo terminou com erro. Código de saída: $($process.ExitCode)" -ForegroundColor Red
        
        # Mostrar conteúdo do log de erro
        if (Test-Path "$logFile.error") {
            $errorContent = Get-Content "$logFile.error" -ErrorAction SilentlyContinue
            if ($errorContent) {
                Write-Host "Conteúdo do log de erro:" -ForegroundColor Red
                foreach ($line in $errorContent) {
                    Write-Host "  ERRO: $line" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "Automação concluída rapidamente com sucesso." -ForegroundColor Green
        
        # Mostrar conteúdo do log
        if (Test-Path $logFile) {
            $logContent = Get-Content $logFile -ErrorAction SilentlyContinue
            if ($logContent) {
                Write-Host "Saída da automação:" -ForegroundColor Cyan
                foreach ($line in $logContent) {
                    Write-Host "  SAÍDA: $line" -ForegroundColor Gray
                }
            }
        }
    }
}

Write-Host "Teste de automação concluído." -ForegroundColor Green
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
