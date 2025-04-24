# Script simplificado para receber dados e executar automação (modo webhook)

# Adicionar referência ao System.Web para codificação de URL
Add-Type -AssemblyName System.Web

# Configurar TLS 1.2 para conexões HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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

# Função para tratar erros de data
function SafeParseDate($dateString) {
    try {
        return [DateTime]::Parse($dateString)
    } catch {
        Log "Aviso: Erro ao analisar data '$dateString'. Usando data atual." "Yellow"
        return Get-Date
    }
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
        # Usar uma data mais antiga para garantir que não perdemos dados
        Log "Última verificação: $script:lastCheckDate" "Cyan"

        # Não usar parâmetro de data para garantir que capturamos todos os dados
        $apiUrl = "https://pin-v2-six.vercel.app/api/data?processed=false"

        # Atualizar a última data verificada para a próxima chamada
        $script:lastCheckDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Log "URL: $apiUrl" "Cyan"

        # Adicionar cabeçalhos para evitar problemas de cache
        $headers = @{
            "Cache-Control" = "no-cache"
            "Pragma" = "no-cache"
            "If-Modified-Since" = "0"
        }

        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers
        Log "Resposta da API recebida com sucesso" "Green"

        # Verificar se a resposta é um array ou um objeto único
        $items = @()

        # Converter a resposta para string para debug
        $responseType = if ($response -eq $null) { "null" } else { $response.GetType().FullName }
        $responseJson = if ($response -eq $null) { "null" } else {
            try { $response | ConvertTo-Json -Depth 3 -Compress } catch { "Não foi possível converter para JSON" }
        }
        Log "Tipo de resposta: $responseType" "Cyan"
        Log "Conteúdo da resposta: $responseJson" "Cyan"

        if ($response -is [Array]) {
            $items = $response
            Log "Recebidos $($items.Count) novos itens (array)" "Green"
        } elseif ($response -is [PSCustomObject]) {
            # Se for um objeto único, adicionar ao array
            if ($response.pin -and $response.name) {
                $items = @($response)
                Log "Recebido 1 novo item (objeto)" "Green"
            } else {
                # Verificar se é um array dentro de um objeto
                if ($response.PSObject.Properties.Name -contains "value" -and $response.value -is [Array]) {
                    $items = $response.value
                    Log "Recebidos $($items.Count) novos itens (array dentro de objeto)" "Green"
                } else {
                    Log "Resposta não contém itens válidos" "Yellow"
                }
            }
        } else {
            Log "Tipo de resposta desconhecido: $responseType" "Yellow"
        }

        if ($items.Count -gt 0) {
            Log "Processando $($items.Count) itens" "Green"

            foreach ($item in $items) {
                Log "Processando item: PIN=$($item.pin), Nome=$($item.name)" "Cyan"

                $success = ExecuteAutomation $item.pin $item.name

                if ($success) {
                    # Marcar item como processado
                    Log "Marcando item como processado na API..." "Cyan"
                    # Usar o ID do item em vez do timestamp
                    $markUrl = "https://pin-v2-six.vercel.app/api/data?single=true&markProcessed=true&id=$($item.id)&processed=false"
                    Log "URL: $markUrl" "Cyan"

                    try {
                        # Adicionar cabeçalhos para evitar problemas de cache
                        $headers = @{
                            "Cache-Control" = "no-cache"
                            "Pragma" = "no-cache"
                            "If-Modified-Since" = "0"
                        }

                        $markResponse = Invoke-RestMethod -Uri $markUrl -Method Get -Headers $headers
                        Log "Item marcado como processado com sucesso" "Green"
                    } catch {
                        Log "Erro ao marcar item como processado: $_" "Red"
                        Log "URL usada: $markUrl" "Yellow"
                    }
                } else {
                    Log "Automação falhou para este item." "Red"
                }

                Log "Processamento do item concluído" "Green"
            }
        } else {
            Log "Nenhum novo item para processar" "Yellow"
        }
    } catch {
        if ($_.Exception.Message -like "*DateTime*") {
            Log "Erro de formato de data na API. Isso é esperado e será corrigido na próxima versão." "Yellow"
            Log "Detalhes: $($_.Exception.Message)" "Yellow"
        } else {
            Log "Erro ao verificar API: $_" "Red"
        }
    }
}

# Variável para armazenar a última data verificada
$script:lastCheckDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Intervalo de verificação em segundos
$checkInterval = 30

Log "Iniciando monitoramento da API..." "Green"
Log "Pressione Ctrl+C para encerrar o script" "Yellow"

# Loop principal - verificar a API a cada X segundos
try {
    while ($true) {
        # Executar a função principal
        CheckForNewData

        # Aguardar o intervalo definido
        Log "Aguardando $checkInterval segundos até a próxima verificação..." "Cyan"
        Start-Sleep -Seconds $checkInterval
    }
} catch {
    Log "Erro no loop principal: $_" "Red"
} finally {
    Log "Script encerrado" "Yellow"
}
