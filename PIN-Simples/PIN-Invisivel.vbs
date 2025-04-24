Option Explicit

' Script para iniciar o servidor webhook de forma totalmente invisível
' Não mostra nenhuma janela ou prompt

' Obter o caminho do script atual
Dim fso, scriptPath, webhookPath
Set fso = CreateObject("Scripting.FileSystemObject")
scriptPath = fso.GetParentFolderName(WScript.ScriptFullName)
webhookPath = scriptPath & "\scripts\WebhookServer.ps1"

' Verificar se o arquivo do webhook existe
If Not fso.FileExists(webhookPath) Then
    MsgBox "Erro: Arquivo do webhook não encontrado: " & webhookPath, vbCritical, "Erro"
    WScript.Quit
End If

' Iniciar o PowerShell de forma invisível
Dim shell, command
Set shell = CreateObject("WScript.Shell")
command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & webhookPath & """"

' Executar o comando sem mostrar janela
shell.Run command, 0, False

' Mostrar notificação na bandeja do sistema
shell.Popup "Servidor webhook iniciado com sucesso!" & vbCrLf & _
           "Aguardando dados do formulário web." & vbCrLf & _
           "O servidor está rodando em segundo plano.", _
           5, "PIN Automação", 64
