# Script simplificado para executar um servidor webhook local
# Este script inicia um servidor HTTP que escuta por requisições POST e executa a automação imediatamente

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

        # Construir argumentos para o script
        $arguments = "--pin `"$pin`" --name `"$name`" --debug"
        Log "Executando comando: node $automationScript $arguments" "Green"

        # Executar o script Node.js diretamente
        $process = Start-Process -FilePath "node" -ArgumentList "$automationScript $arguments" -NoNewWindow:$false -PassThru

        Log "Processo iniciado com ID: $($process.Id)" "Green"
        Log "Automação em execução. Navegador Chromium deve estar visível." "Green"

        # Não aguardar o processo terminar - deixar executar em segundo plano
        return $true
    } catch {
        Log "ERRO ao iniciar automação: $_" "Red"
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
                SendResponse $request 200 "Automação iniciada com sucesso!"
            } else {
                SendResponse $request 500 "Falha ao iniciar automação"
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

# Iniciar o servidor
try {
    $listener.Start()
    Log "Servidor webhook iniciado em $prefix" "Green"
    Log "Aguardando requisições..." "Yellow"
    Log "Pressione Ctrl+C para encerrar o servidor" "Yellow"

    # Loop principal simplificado
    while ($true) {
        # Aguardar uma requisição
        $context = $listener.GetContext()

        # Processar a requisição
        ProcessRequest $context.Request
    }
} catch [System.OperationCanceledException] {
    # Ignorar exceção de cancelamento (Ctrl+C)
    Log "Servidor interrompido pelo usuário" "Yellow"
} catch {
    Log "Erro no servidor: $_" "Red"
} finally {
    # Parar o servidor
    if ($listener -ne $null -and $listener.IsListening) {
        $listener.Stop()
        Log "Servidor webhook encerrado" "Yellow"
    }
}
