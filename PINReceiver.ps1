# Script PowerShell para receber dados do formulário web
# Este script pode ser convertido em executável usando PS2EXE

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configurações
$apiUrl = "https://pin-v2-six.vercel.app/api/data"
$checkInterval = 30 # segundos
$appDataFolder = [System.IO.Path]::Combine($env:APPDATA, "PINReceiverApp")
$dataFilePath = [System.IO.Path]::Combine($appDataFolder, "received_data.json")
$lastCheckTime = (Get-Date).AddMinutes(-5) # Verificar dados dos últimos 5 minutos no início

# Criar pasta para armazenar dados se não existir
if (-not (Test-Path $appDataFolder)) {
    New-Item -ItemType Directory -Path $appDataFolder | Out-Null
}

# Carregar dados existentes
function LoadData {
    if (Test-Path $dataFilePath) {
        try {
            $content = Get-Content -Path $dataFilePath -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Host "Arquivo de dados vazio, iniciando com array vazio"
                return @()
            }

            $data = $content | ConvertFrom-Json -ErrorAction Stop

            # Verificar se o resultado é um array
            if ($data -isnot [array]) {
                Write-Host "Dados carregados não são um array, convertendo"
                $data = @($data)
            }

            Write-Host "Dados carregados com sucesso: $($data.Count) itens"

            # Converter para array normal para evitar problemas com PSObjects
            $resultArray = @()
            foreach ($item in $data) {
                # Converter cada item para um hashtable normal
                $hashtable = @{}
                foreach ($prop in $item.PSObject.Properties) {
                    $hashtable[$prop.Name] = $prop.Value
                }
                $resultArray += $hashtable
            }

            return $resultArray
        }
        catch {
            Write-Host "Erro ao carregar dados: $_"
            # Fazer backup do arquivo com problema
            $backupPath = "$dataFilePath.bak"
            try {
                Copy-Item -Path $dataFilePath -Destination $backupPath -Force -ErrorAction SilentlyContinue
                Write-Host "Backup do arquivo de dados criado em: $backupPath"
            }
            catch {
                Write-Host "Não foi possível criar backup: $_"
            }
            return @()
        }
    }
    else {
        Write-Host "Arquivo de dados não encontrado, iniciando com array vazio"
        return @()
    }
}

# Salvar dados
function SaveData($data) {
    try {
        # Verificar se os dados são válidos
        if ($null -eq $data) {
            Write-Host "Aviso: Tentativa de salvar dados nulos, usando array vazio"
            $data = @()
        }

        # Garantir que estamos salvando um array
        if ($data -isnot [array]) {
            Write-Host "Aviso: Convertendo dados para array antes de salvar"
            $data = @($data)
        }

        # Criar backup do arquivo atual se existir
        if (Test-Path $dataFilePath) {
            $backupPath = "$dataFilePath.previous"
            try {
                Copy-Item -Path $dataFilePath -Destination $backupPath -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Não foi possível criar backup antes de salvar: $_"
            }
        }

        # Converter para JSON e salvar
        $json = ConvertTo-Json -InputObject $data -Depth 10 -ErrorAction Stop
        Set-Content -Path $dataFilePath -Value $json -ErrorAction Stop
        Write-Host "Dados salvos com sucesso: $($data.Count) itens"
    }
    catch {
        Write-Host "Erro ao salvar dados: $_"
    }
}

# Verificar novos dados
function CheckForNewData {
    try {
        $since = $lastCheckTime.ToString("o")
        $url = "$apiUrl`?since=$since&processed=false"
        $script:lastCheckTime = Get-Date

        # Usar try-catch específico para a chamada de API
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -UseBasicParsing
        }
        catch {
            Write-Host "Erro ao chamar a API: $_"
            return $null
        }

        # Verificar se a resposta está vazia
        if ($null -eq $response -or ($response -is [array] -and $response.Count -eq 0)) {
            # Sem novos dados
            return $null
        }

        # Se a resposta for um array, processar cada item
        if ($response -is [array]) {
            Write-Host "Recebidos $($response.Count) novos itens"
            foreach ($item in $response) {
                if ($item.PIN -and $item.Name -and $item.timestamp) {
                    ProcessNewData $item
                }
                else {
                    Write-Host "Item recebido com formato inválido: $($item | ConvertTo-Json -Compress)"
                }
            }
            return $response
        }
        # Se a resposta for um único objeto com PIN
        elseif ($response.PIN -and $response.Name -and $response.timestamp) {
            Write-Host "Recebido 1 novo item"
            ProcessNewData $response
            return $response
        }
        else {
            Write-Host "Resposta recebida em formato inesperado: $($response | ConvertTo-Json -Compress)"
            return $null
        }
    }
    catch {
        Write-Host "Erro ao verificar novos dados: $_"
        return $null
    }
}

# Processar um novo item de dados
function ProcessNewData($item) {
    # Verificar se já processamos este item antes (baseado no timestamp)
    $existingItem = $script:receivedData | Where-Object { $_.OriginalTimestamp -eq $item.timestamp }
    if ($existingItem) {
        Write-Host "Item já processado anteriormente. Ignorando."
        return
    }

    # Criar novo objeto de dados
    $newData = [ordered]@{
        PIN = $item.PIN
        Name = $item.Name
        ReceivedAt = (Get-Date).ToString("o")
        AutomationStatus = "Iniciando automação..."
        OriginalTimestamp = $item.timestamp
    }

    # Adicionar aos dados armazenados (usando ArrayList para evitar problemas com +=)
    if ($null -eq $script:receivedData) {
        $script:receivedData = New-Object System.Collections.ArrayList
    }

    if ($script:receivedData -is [array] -and $script:receivedData -isnot [System.Collections.ArrayList]) {
        $tempArray = New-Object System.Collections.ArrayList
        foreach ($item in $script:receivedData) {
            $tempArray.Add($item) | Out-Null
        }
        $script:receivedData = $tempArray
    }

    # Usar o método Add em vez do operador +=
    $script:receivedData.Add($newData) | Out-Null
    SaveData $script:receivedData

    # Mostrar notificação
    $trayIcon.BalloonTipTitle = "Novos dados recebidos!"
    $trayIcon.BalloonTipText = "PIN: $($newData.PIN), Nome: $($newData.Name)"
    $trayIcon.ShowBalloonTip(5000)

    # Executar automação
    ExecuteAutomation $newData

    # Marcar como processado na API
    try {
        $markUrl = "$apiUrl`?single=true&markProcessed=true&since=$($item.timestamp)&processed=false"
        Invoke-RestMethod -Uri $markUrl -Method Get -UseBasicParsing | Out-Null
    } catch {
        Write-Host "Erro ao marcar item como processado: $_"
    }
}

# Executar automação
function ExecuteAutomation($data) {
    try {
        # Atualizar status
        $data.AutomationStatus = "Em execução..."
        SaveData $script:receivedData
        UpdateAutomationStatus "Executando automação para PIN: $($data.PIN)..."

        # Obter o caminho do script de automação
        $scriptDir = Split-Path -Parent $PSScriptRoot
        $automationScript = Join-Path -Path $scriptDir -ChildPath "automation.js"

        # Verificar se o script existe
        if (-not (Test-Path $automationScript)) {
            throw "Script de automação não encontrado: $automationScript"
        }

        UpdateAutomationStatus "Iniciando Puppeteer para PIN: $($data.PIN), Nome: $($data.Name)..."

        # Executar o script Node.js com Puppeteer
        $nodeExe = "node"
        $debug = $true  # Modo de depuração ativado para mostrar o navegador

        # Construir argumentos para o script
        $arguments = @(
            $automationScript,
            "--pin", $data.PIN,
            "--name", $data.Name
        )

        if ($debug) {
            $arguments += "--debug"
        }

        # Executar o comando Node.js
        $process = Start-Process -FilePath $nodeExe -ArgumentList $arguments -NoNewWindow -PassThru -Wait

        # Verificar o código de saída
        if ($process.ExitCode -ne 0) {
            throw "Erro na execução do script de automação. Código de saída: $($process.ExitCode)"
        }

        UpdateAutomationStatus "Puppeteer executado com sucesso!"

        # Atualizar status de conclusão
        $data.AutomationStatus = "Concluída com sucesso"
        $data.AutomationCompletedAt = (Get-Date).ToString("o")
        SaveData $script:receivedData
        UpdateAutomationStatus "Automação concluída com sucesso!"

        return $true
    } catch {
        $data.AutomationStatus = "Erro: $_"
        SaveData $script:receivedData
        UpdateAutomationStatus "Erro na automação: $_"
        return $false
    }
}

# Atualizar status da automação no menu
function UpdateAutomationStatus($status) {
    $automationStatusItem.Text = "Status da automação: $status"
}

# Carregar dados existentes
$loadedData = LoadData

# Inicializar receivedData como ArrayList
$script:receivedData = New-Object System.Collections.ArrayList

# Adicionar dados carregados ao ArrayList
if ($loadedData -and $loadedData.Count -gt 0) {
    foreach ($item in $loadedData) {
        $script:receivedData.Add($item) | Out-Null
    }
    Write-Host "Dados carregados e convertidos para ArrayList: $($script:receivedData.Count) itens"
}

# Criar formulário para visualizar dados
function ShowDataViewer {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Dados de PIN Recebidos"
    $form.Size = New-Object System.Drawing.Size(800, 400)
    $form.StartPosition = "CenterScreen"

    $listView = New-Object System.Windows.Forms.ListView
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.GridLines = $true
    $listView.Dock = [System.Windows.Forms.DockStyle]::Fill

    # Adicionar colunas
    $listView.Columns.Add("PIN", 80) | Out-Null
    $listView.Columns.Add("Nome", 150) | Out-Null
    $listView.Columns.Add("Data/Hora de Recebimento", 150) | Out-Null
    $listView.Columns.Add("Status da Automação", 150) | Out-Null
    $listView.Columns.Add("Automação Concluída em", 150) | Out-Null

    # Adicionar dados
    $sortedData = $script:receivedData | Sort-Object { [DateTime]::Parse($_.ReceivedAt) } -Descending

    foreach ($data in $sortedData) {
        $item = New-Object System.Windows.Forms.ListViewItem($data.PIN)
        $item.SubItems.Add($data.Name) | Out-Null
        $item.SubItems.Add([DateTime]::Parse($data.ReceivedAt).ToString("dd/MM/yyyy HH:mm:ss")) | Out-Null
        $item.SubItems.Add($data.AutomationStatus -or "Não iniciada") | Out-Null

        if ($data.AutomationCompletedAt) {
            $item.SubItems.Add([DateTime]::Parse($data.AutomationCompletedAt).ToString("dd/MM/yyyy HH:mm:ss")) | Out-Null
        } else {
            $item.SubItems.Add("-") | Out-Null
        }

        # Colorir a linha de acordo com o status da automação
        if ($data.AutomationStatus) {
            if ($data.AutomationStatus -like "Concluída*") {
                $item.BackColor = [System.Drawing.Color]::LightGreen
            } elseif ($data.AutomationStatus -like "Erro*" -or $data.AutomationStatus -like "Falhou*") {
                $item.BackColor = [System.Drawing.Color]::LightPink
            } else {
                $item.BackColor = [System.Drawing.Color]::LightYellow
            }
        }

        $listView.Items.Add($item) | Out-Null
    }

    # Botão de atualização
    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Atualizar"
    $btnRefresh.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $btnRefresh.Height = 30
    $btnRefresh.Add_Click({
        $listView.Items.Clear()

        $sortedData = $script:receivedData | Sort-Object { [DateTime]::Parse($_.ReceivedAt) } -Descending

        foreach ($data in $sortedData) {
            $item = New-Object System.Windows.Forms.ListViewItem($data.PIN)
            $item.SubItems.Add($data.Name) | Out-Null
            $item.SubItems.Add([DateTime]::Parse($data.ReceivedAt).ToString("dd/MM/yyyy HH:mm:ss")) | Out-Null
            $item.SubItems.Add($data.AutomationStatus -or "Não iniciada") | Out-Null

            if ($data.AutomationCompletedAt) {
                $item.SubItems.Add([DateTime]::Parse($data.AutomationCompletedAt).ToString("dd/MM/yyyy HH:mm:ss")) | Out-Null
            } else {
                $item.SubItems.Add("-") | Out-Null
            }

            # Colorir a linha de acordo com o status da automação
            if ($data.AutomationStatus) {
                if ($data.AutomationStatus -like "Concluída*") {
                    $item.BackColor = [System.Drawing.Color]::LightGreen
                } elseif ($data.AutomationStatus -like "Erro*" -or $data.AutomationStatus -like "Falhou*") {
                    $item.BackColor = [System.Drawing.Color]::LightPink
                } else {
                    $item.BackColor = [System.Drawing.Color]::LightYellow
                }
            }

            $listView.Items.Add($item) | Out-Null
        }
    })

    # Adicionar controles ao formulário
    $form.Controls.Add($listView)
    $form.Controls.Add($btnRefresh)

    # Mostrar formulário
    $form.Add_FormClosing({
        $_.Cancel = $true
        $form.Hide()
    })

    $form.ShowDialog() | Out-Null
}

# Criar ícone na bandeja do sistema
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = "Receptor de PIN - Em execução"
$trayIcon.Visible = $true

# Usar ícone do sistema
$trayIcon.Icon = [System.Drawing.SystemIcons]::Application

# Criar menu de contexto
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$checkNowItem = New-Object System.Windows.Forms.ToolStripMenuItem
$checkNowItem.Text = "Verificar agora"
$checkNowItem.Add_Click({
    $trayIcon.BalloonTipTitle = "Receptor de PIN"
    $trayIcon.BalloonTipText = "Verificando novos dados..."
    $trayIcon.ShowBalloonTip(3000)

    $newData = CheckForNewData
    if (-not $newData) {
        $trayIcon.BalloonTipTitle = "Receptor de PIN"
        $trayIcon.BalloonTipText = "Nenhum novo dado encontrado."
        $trayIcon.ShowBalloonTip(3000)
    }
})
$contextMenu.Items.Add($checkNowItem) | Out-Null

$viewDataItem = New-Object System.Windows.Forms.ToolStripMenuItem
$viewDataItem.Text = "Ver dados recebidos"
$viewDataItem.Add_Click({
    ShowDataViewer
})
$contextMenu.Items.Add($viewDataItem) | Out-Null

$contextMenu.Items.Add("-") | Out-Null

$automationStatusItem = New-Object System.Windows.Forms.ToolStripMenuItem
$automationStatusItem.Text = "Status da automação: Aguardando dados"
$automationStatusItem.Enabled = $false
$contextMenu.Items.Add($automationStatusItem) | Out-Null

$contextMenu.Items.Add("-") | Out-Null

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitItem.Text = "Sair"
$exitItem.Add_Click({
    $trayIcon.Visible = $false
    $timer.Stop()
    $timer.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($exitItem) | Out-Null

$trayIcon.ContextMenuStrip = $contextMenu

# Mostrar notificação inicial
$trayIcon.BalloonTipTitle = "Receptor de PIN"
$trayIcon.BalloonTipText = "Aplicativo iniciado e rodando em segundo plano."
$trayIcon.ShowBalloonTip(3000)

# Configurar timer para verificar novos dados
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $checkInterval * 1000
$timer.Add_Tick({
    CheckForNewData | Out-Null
})
$timer.Start()

# Manter o aplicativo em execução
$appContext = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($appContext)
