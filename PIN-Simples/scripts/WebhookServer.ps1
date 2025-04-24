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
function ProcessRequest($context) {
    try {
        $request = $context.Request
        Log "Requisição recebida: $($request.HttpMethod) $($request.Url.PathAndQuery)" "Cyan"

        # Verificar se é uma requisição POST
        if ($request.HttpMethod -ne "POST") {
            Log "Método não permitido: $($request.HttpMethod)" "Yellow"

            # Se for GET, mostrar uma página amigável
            if ($request.HttpMethod -eq "GET") {
                $htmlResponse = @"
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Webhook PIN</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #0070f3; }
        .status { background-color: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .status.success { background-color: #e8f5e9; color: #2e7d32; }
        .info { background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        code { background-color: #f5f5f5; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>Servidor Webhook PIN</h1>
    <div class="status success">
        <strong>Status:</strong> Servidor rodando e aguardando dados
    </div>
    <div class="info">
        <p>Este é o servidor webhook para automação PIN. Ele está funcionando corretamente e aguardando dados do formulário web.</p>
        <p>Endereço do servidor: <code>http://localhost:8080</code></p>
        <p>Para usar:</p>
        <ol>
            <li>Mantenha este servidor rodando</li>
            <li>Acesse o formulário web: <a href="https://pin-v2-six.vercel.app/" target="_blank">https://pin-v2-six.vercel.app/</a></li>
            <li>Preencha o PIN e Nome e clique em Enviar</li>
            <li>A automação será executada imediatamente neste computador</li>
        </ol>
    </div>
    <p><small>Servidor iniciado em: $(Get-Date)</small></p>
</body>
</html>
"@
                # Usar o contexto completo para a resposta
                $response = $context.Response
                $response.StatusCode = 200
                $response.ContentType = "text/html"

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($htmlResponse)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()

                Log "Resposta HTML enviada: 200" "Green"
                return
            }

            # Usar o contexto completo para a resposta
            $response = $context.Response
            $response.StatusCode = 405
            $response.ContentType = "text/plain"

            $buffer = [System.Text.Encoding]::UTF8.GetBytes("Method Not Allowed")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()

            Log "Resposta enviada: 405 Method Not Allowed" "Yellow"
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

                # Usar o contexto completo para a resposta
                $response = $context.Response
                $response.StatusCode = 400
                $response.ContentType = "text/plain"

                $message = "Bad Request: PIN and name are required"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()

                Log "Resposta enviada: 400 $message" "Yellow"
                return
            }

            # Executar a automação
            Log "Dados recebidos: PIN=$($data.pin), Nome=$($data.name)" "Green"
            $success = ExecuteAutomation $data.pin $data.name

            # Enviar resposta
            $response = $context.Response

            if ($success) {
                $response.StatusCode = 200
                $message = "Automação iniciada com sucesso!"
            } else {
                $response.StatusCode = 500
                $message = "Falha ao iniciar automação"
            }

            $response.ContentType = "text/plain"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()

            Log "Resposta enviada: $($response.StatusCode) $message" "Green"
        } catch {
            Log "Erro ao processar JSON: $_" "Red"

            # Usar o contexto completo para a resposta
            $response = $context.Response
            $response.StatusCode = 400
            $response.ContentType = "text/plain"

            $message = "Bad Request: Invalid JSON"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()

            Log "Resposta enviada: 400 $message" "Yellow"
        }
    } catch {
        Log "Erro ao processar requisição: $_" "Red"

        # Usar o contexto completo para a resposta
        try {
            $response = $context.Response
            $response.StatusCode = 500
            $response.ContentType = "text/plain"

            $message = "Internal Server Error"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()

            Log "Resposta enviada: 500 $message" "Red"
        } catch {
            Log "Erro crítico ao enviar resposta de erro: $_" "Red"
        }
    }
}

# Função para enviar resposta HTTP
function SendResponse($request, $statusCode, $message) {
    try {
        # Obter o objeto de resposta do contexto
        $response = $request.HttpListenerContext.Response
        $response.StatusCode = $statusCode
        $response.StatusDescription = $message

        # Converter a mensagem para bytes
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $responseBytes.Length
        $response.ContentType = "text/plain"

        # Escrever a resposta
        $output = $response.OutputStream
        $output.Write($responseBytes, 0, $responseBytes.Length)
        $output.Close()

        Log "Resposta enviada: $statusCode $message" "Green"
    } catch {
        Log "Erro ao enviar resposta: $_" "Red"
    }
}

# Função para enviar resposta HTML
function SendHtmlResponse($request, $statusCode, $htmlContent) {
    try {
        # Obter o objeto de resposta do contexto
        $response = $request.HttpListenerContext.Response
        $response.StatusCode = $statusCode

        # Converter o HTML para bytes
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($htmlContent)
        $response.ContentLength64 = $responseBytes.Length
        $response.ContentType = "text/html"

        # Escrever a resposta
        $output = $response.OutputStream
        $output.Write($responseBytes, 0, $responseBytes.Length)
        $output.Close()

        Log "Resposta HTML enviada: $statusCode" "Green"
    } catch {
        Log "Erro ao enviar resposta HTML: $_" "Red"
    }
}

# Configuração do servidor HTTP
$port = 8081  # Mudando para porta 8081
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

        # Processar a requisição com o contexto completo
        ProcessRequest $context
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
