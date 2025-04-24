# Script simplificado para receber dados e executar automação (modo webhook)

# Função para registrar logs
function Log($message, $color = "White") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"

    # Mostrar na tela
    Write-Host $logMessage -ForegroundColor $color

    # Salvar no arquivo de log
    $appDataFolder = [System.IO.Path]::Combine($env:APPDATA, "PINReceiverApp")
    if (-not (Test-Path $appDataFolder)) {
        New-Item -ItemType Directory -Path $appDataFolder -Force | Out-Null
    }

    $logFile = [System.IO.Path]::Combine($appDataFolder, "pin-receiver.log")
    Add-Content -Path $logFile -Value $logMessage
}

# Função para executar a automação
function ExecuteAutomation($pin, $name) {
    Log "Iniciando automação para PIN: $pin, Nome: $name" "Green"

    try {
        # Caminho fixo para o script de automação
        $automationScript = Join-Path -Path $PSScriptRoot -ChildPath "automacao-puppeteer.js"

        # Verificar se o script existe
        if (-not (Test-Path $automationScript)) {
            Log "ERRO: Script de automação não encontrado: $automationScript" "Red"
            throw "Script de automação não encontrado: $automationScript"
        }

        Log "Script de automação encontrado: $automationScript" "Green"

        # Construir argumentos para o script
        $arguments = "--pin `"$pin`" --name `"$name`" --debug"
        Log "Executando comando: node $automationScript $arguments" "Cyan"

        # Executar o script Node.js diretamente
        $process = Start-Process -FilePath "node" -ArgumentList "$automationScript $arguments" -NoNewWindow:$false -PassThru

        Log "Processo iniciado com ID: $($process.Id)" "Green"

        # Aguardar um pouco para que o processo inicie
        Start-Sleep -Seconds 5

        # Verificar se o processo ainda está em execução
        if (-not $process.HasExited) {
            Log "Automação em execução. Navegador Chromium deve estar visível." "Green"

            # Aguardar mais um pouco para dar tempo de completar
            Start-Sleep -Seconds 10

            # Verificar novamente
            if (-not $process.HasExited) {
                Log "Automação ainda em execução. Aguardando conclusão..." "Yellow"
                $process.WaitForExit(60000) # Aguardar até 60 segundos
            }
        }

        # Verificar o resultado
        if ($process.HasExited) {
            if ($process.ExitCode -ne 0) {
                Log "Processo terminou com erro. Código de saída: $($process.ExitCode)" "Red"
                return $false
            } else {
                Log "Automação concluída com sucesso." "Green"
                return $true
            }
        } else {
            Log "Automação ainda em execução após tempo limite. Considerando como sucesso." "Yellow"
            return $true
        }
    } catch {
        Log "ERRO CRÍTICO ao iniciar processo: $_" "Red"

        # Tentar obter mais informações sobre o erro
        Log "Detalhes do erro:" "Red"
        Log "  Tipo de exceção: $($_.Exception.GetType().FullName)" "Red"
        Log "  Mensagem: $($_.Exception.Message)" "Red"
        Log "  Local: $($_.InvocationInfo.PositionMessage)" "Red"

        return $false
    }
}

# Função principal - Verificar novos dados da API (webhook)
function CheckForNewData() {
    Log "Verificando novos dados na API..." "Cyan"

    try {
        # Usar a data atual para verificar novos dados
        $currentDate = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        $apiUrl = "https://pin-v2-six.vercel.app/api/data?since=$currentDate&processed=false"
        Log "URL: $apiUrl" "Cyan"

        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        Log "Resposta da API recebida com sucesso" "Green"

        if ($response.Count -gt 0) {
            Log "Recebidos $($response.Count) novos itens" "Green"

            foreach ($item in $response) {
                Log "Processando item: PIN=$($item.pin), Nome=$($item.name)" "Cyan"

                $success = ExecuteAutomation $item.pin $item.name

                if ($success) {
                    # Marcar item como processado
                    Log "Marcando item como processado na API..." "Cyan"
                    $markUrl = "https://pin-v2-six.vercel.app/api/data?single=true&markProcessed=true&since=$($item.timestamp)&processed=false"
                    Log "URL: $markUrl" "Cyan"

                    try {
                        $markResponse = Invoke-RestMethod -Uri $markUrl -Method Get
                        Log "Item marcado como processado com sucesso" "Green"
                    } catch {
                        Log "Erro ao marcar item como processado: $_" "Red"
                    }
                } else {
                    Log "Automação falhou para este item." "Red"
                }

                Log "Processamento do item concluído" "Green"
            }
        } else {
            Log "Nenhum novo item encontrado" "Yellow"
        }
    } catch {
        Log "Erro ao verificar API: $_" "Red"
    }
}

# Executar a função principal
CheckForNewData
