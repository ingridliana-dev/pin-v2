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
            $data = Get-Content -Path $dataFilePath -Raw | ConvertFrom-Json
            return $data
        } catch {
            Write-Host "Erro ao carregar dados: $_"
            return @()
        }
    } else {
        return @()
    }
}

# Salvar dados
function SaveData($data) {
    try {
        $json = ConvertTo-Json -InputObject $data -Depth 10
        Set-Content -Path $dataFilePath -Value $json
    } catch {
        Write-Host "Erro ao salvar dados: $_"
    }
}

# Verificar novos dados
function CheckForNewData {
    try {
        $since = $lastCheckTime.ToString("o")
        $url = "$apiUrl`?since=$since"
        $lastCheckTime = Get-Date
        
        $response = Invoke-RestMethod -Uri $url -Method Get -UseBasicParsing
        
        if ($response -and $response.PIN) {
            $newData = @{
                PIN = $response.PIN
                Name = $response.Name
                ReceivedAt = (Get-Date).ToString("o")
                AutomationStatus = "Iniciando automação..."
            }
            
            $script:receivedData += $newData
            SaveData $script:receivedData
            
            # Mostrar notificação
            $trayIcon.BalloonTipTitle = "Novos dados recebidos!"
            $trayIcon.BalloonTipText = "PIN: $($newData.PIN), Nome: $($newData.Name)"
            $trayIcon.ShowBalloonTip(5000)
            
            # Executar automação
            ExecuteAutomation $newData
            
            return $newData
        }
        
        return $null
    } catch {
        Write-Host "Erro ao verificar novos dados: $_"
        return $null
    }
}

# Executar automação
function ExecuteAutomation($data) {
    try {
        # Atualizar status
        $data.AutomationStatus = "Em execução..."
        SaveData $script:receivedData
        UpdateAutomationStatus "Executando automação para PIN: $($data.PIN)..."
        
        # Simular passos da automação
        Start-Sleep -Seconds 1
        UpdateAutomationStatus "Preenchendo PIN: $($data.PIN)..."
        Start-Sleep -Milliseconds 500
        
        UpdateAutomationStatus "Preenchendo Nome: $($data.Name)..."
        Start-Sleep -Milliseconds 500
        
        UpdateAutomationStatus "Enviando dados..."
        Start-Sleep -Seconds 1
        
        # Aqui você pode implementar a automação real
        # Por exemplo, usando SendKeys para enviar teclas para aplicativos:
        # [System.Windows.Forms.SendKeys]::SendWait($data.PIN)
        # [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        # [System.Windows.Forms.SendKeys]::SendWait($data.Name)
        
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
$script:receivedData = LoadData

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
