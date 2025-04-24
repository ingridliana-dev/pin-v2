# Script para executar um servidor webhook local
# Este script inicia um servidor HTTP que escuta por requisições POST e executa a automação imediatamente

# Adicionar referência ao System.Web para codificação de URL
Add-Type -AssemblyName System.Web

# Configurar TLS 1.2 para conexões HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Configurar codificação UTF-8 para evitar problemas com caracteres especiais
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

    $logFile = [System.IO.Path]::Combine($appDataFolder, "webhook-server.log")
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

# Função para processar requisições HTTP
function ProcessRequest($request) {
    try {
        Log "Requisição recebida: $($request.HttpMethod) $($request.Url.PathAndQuery)" "Cyan"
        
        # Verificar se é uma requisição POST
        if ($request.HttpMethod -ne "POST") {
            Log "Método não permitido: $($request.HttpMethod)" "Yellow"
            SendResponse $request 405 "Method Not Allowed"
            return
        }
        
        # Ler o corpo da requisição
        $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
        $body = $reader.ReadToEnd()
        $reader.Close()
        
        Log "Corpo da requisição: $body" "Cyan"
        
        # Processar o JSON
        try {
            $data = $body | ConvertFrom-Json
            
            # Verificar se os campos necessários estão presentes
            if (-not $data.pin -or -not $data.name) {
                Log "Campos obrigatórios ausentes" "Yellow"
                SendResponse $request 400 "Bad Request: PIN and name are required"
                return
            }
            
            # Executar a automação
            Log "Dados recebidos: PIN=$($data.pin), Nome=$($data.name)" "Green"
            $success = ExecuteAutomation $data.pin $data.name
            
            # Enviar resposta
            if ($success) {
                SendResponse $request 200 "Automation executed successfully"
            } else {
                SendResponse $request 500 "Automation failed"
            }
        } catch {
            Log "Erro ao processar JSON: $_" "Red"
            SendResponse $request 400 "Bad Request: Invalid JSON"
        }
    } catch {
        Log "Erro ao processar requisição: $_" "Red"
        SendResponse $request 500 "Internal Server Error"
    }
}

# Função para enviar resposta HTTP
function SendResponse($request, $statusCode, $message) {
    try {
        $response = $request.GetResponse()
        $response.StatusCode = $statusCode
        $response.StatusDescription = $message
        
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $responseBytes.Length
        $response.ContentType = "text/plain"
        
        $output = $response.OutputStream
        $output.Write($responseBytes, 0, $responseBytes.Length)
        $output.Close()
        
        Log "Resposta enviada: $statusCode $message" "Green"
    } catch {
        Log "Erro ao enviar resposta: $_" "Red"
    }
}

# Configuração do servidor HTTP
$port = 8080
$prefix = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    # Iniciar o servidor
    $listener.Start()
    Log "Servidor webhook iniciado em $prefix" "Green"
    Log "Aguardando requisições..." "Yellow"
    
    # Loop principal
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Processar a requisição em uma nova thread
        $thread = [System.Threading.ThreadPool]::QueueUserWorkItem(
            [System.Threading.WaitCallback]{ 
                param($req)
                ProcessRequest $req
            }, 
            $request
        )
    }
} catch {
    Log "Erro no servidor: $_" "Red"
} finally {
    # Parar o servidor
    if ($listener -ne $null) {
        $listener.Stop()
        $listener.Close()
    }
    Log "Servidor webhook encerrado" "Yellow"
}
