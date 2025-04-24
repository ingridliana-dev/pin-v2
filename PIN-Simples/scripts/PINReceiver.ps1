# Script simplificado para receber dados e executar automação (modo webhook)

# Adicionar referência ao System.Web para codificação de URL
Add-Type -AssemblyName System.Web

# Configurar TLS 1.2 para conexões HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Configurar codificação UTF-8 para evitar problemas com caracteres especiais
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ignorar erros de certificado SSL (apenas para desenvolvimento)
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
    $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            ServicePointManager.ServerCertificateValidationCallback +=
                delegate
                (
                    Object obj,
                    X509Certificate certificate,
                    X509Chain chain,
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()

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
        # Não usar parâmetro de data para garantir que capturamos todos os dados
        $apiUrl = "https://pin-v2-six.vercel.app/api/data?processed=false"
        Log "URL: $apiUrl" "Cyan"

        # Usar método simples para obter dados
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing
        Log "Resposta da API recebida com sucesso" "Green"

        # Processar a resposta
        $items = @()

        # Extrair o conteúdo da resposta
        $responseContent = $response.Content
        Log "Conteúdo da resposta: $responseContent" "Cyan"

        # Converter o conteúdo JSON para objeto PowerShell
        try {
            $responseData = $responseContent | ConvertFrom-Json

            # Verificar se é um array
            if ($responseData -is [Array]) {
                $items = $responseData
                Log "Recebidos $($items.Count) novos itens (array)" "Green"
            }
            # Verificar se é um objeto único
            elseif ($responseData -is [PSCustomObject]) {
                if ($responseData.pin -and $responseData.name) {
                    $items = @($responseData)
                    Log "Recebido 1 novo item (objeto)" "Green"
                } else {
                    Log "Resposta não contém itens válidos" "Yellow"
                }
            } else {
                Log "Tipo de resposta desconhecido" "Yellow"
            }
        } catch {
            Log "Erro ao processar resposta JSON: $_" "Red"
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
                        # Usar método simples para marcar como processado
                        $markResponse = Invoke-WebRequest -Uri $markUrl -UseBasicParsing
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
