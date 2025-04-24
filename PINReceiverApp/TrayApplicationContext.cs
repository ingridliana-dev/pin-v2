using System;
using System.Drawing;
using System.Windows.Forms;
using System.Threading.Tasks;

namespace PINReceiverApp
{
    public class TrayApplicationContext : ApplicationContext
    {
        private NotifyIcon trayIcon;
        private ContextMenuStrip contextMenu;
        private PINDataReceiver dataReceiver;
        private System.Threading.Timer checkTimer;
        private FormDataViewer dataViewerForm;
        private ToolStripMenuItem automationStatusItem;

        public TrayApplicationContext()
        {
            // Inicializar o receptor de dados
            dataReceiver = new PINDataReceiver();

            // Configurar eventos do receptor de dados
            dataReceiver.NewDataReceived += OnNewDataReceived;
            dataReceiver.AutomationProgressUpdated += OnAutomationProgressUpdated;

            // Configurar o menu de contexto
            contextMenu = new ContextMenuStrip();
            contextMenu.Items.Add("Verificar agora", null, OnCheckNow);
            contextMenu.Items.Add("Ver dados recebidos", null, OnViewData);
            contextMenu.Items.Add("-"); // Separador

            // Adicionar item de status da automação
            automationStatusItem = new ToolStripMenuItem("Status da automação: Aguardando dados") { Enabled = false };
            contextMenu.Items.Add(automationStatusItem);

            contextMenu.Items.Add("-"); // Separador
            contextMenu.Items.Add("Sair", null, OnExit);

            // Configurar o ícone da bandeja
            trayIcon = new NotifyIcon()
            {
                Icon = SystemIcons.Application, // Substituir por um ícone personalizado
                ContextMenuStrip = contextMenu,
                Text = "Receptor de PIN - Em execução",
                Visible = true
            };

            trayIcon.DoubleClick += OnViewData;

            // Iniciar o timer para verificar novos dados a cada 30 segundos
            checkTimer = new System.Threading.Timer(
                CheckForNewData,
                null,
                TimeSpan.Zero,
                TimeSpan.FromSeconds(30)
            );

            // Mostrar notificação inicial
            trayIcon.ShowBalloonTip(
                3000,
                "Receptor de PIN",
                "Aplicativo iniciado e rodando em segundo plano.",
                ToolTipIcon.Info
            );
        }

        private void CheckForNewData(object state)
        {
            Task.Run(async () =>
            {
                try
                {
                    var newData = await dataReceiver.CheckForNewDataAsync();
                    // A notificação agora é tratada pelo evento OnNewDataReceived
                }
                catch (Exception ex)
                {
                    // Registrar erro, mas não mostrar para o usuário para manter o app em segundo plano
                    Console.WriteLine($"Erro ao verificar novos dados: {ex.Message}");
                    UpdateAutomationStatus($"Erro: {ex.Message}");
                }
            });
        }

        private void OnNewDataReceived(object sender, PINData newData)
        {
            // Mostrar notificação de novos dados
            trayIcon.ShowBalloonTip(
                5000,
                "Novos dados recebidos!",
                $"PIN: {newData.PIN}, Nome: {newData.Name}",
                ToolTipIcon.Info
            );

            // Atualizar o status da automação
            UpdateAutomationStatus("Iniciando automação...");
        }

        private void OnAutomationProgressUpdated(object sender, string message)
        {
            // Atualizar o status da automação no menu de contexto
            UpdateAutomationStatus(message);
        }

        private void UpdateAutomationStatus(string status)
        {
            // Atualizar o item de menu na thread da UI
            if (contextMenu.InvokeRequired)
            {
                contextMenu.Invoke(new Action<string>(UpdateAutomationStatus), status);
                return;
            }

            automationStatusItem.Text = $"Status da automação: {status}";
        }

        private void OnCheckNow(object sender, EventArgs e)
        {
            CheckForNewData(null);
            trayIcon.ShowBalloonTip(
                3000,
                "Receptor de PIN",
                "Verificando novos dados...",
                ToolTipIcon.Info
            );
        }

        private void OnViewData(object sender, EventArgs e)
        {
            // Se o formulário já estiver aberto, apenas traga-o para frente
            if (dataViewerForm != null && !dataViewerForm.IsDisposed)
            {
                dataViewerForm.BringToFront();
                return;
            }

            // Caso contrário, crie um novo formulário
            dataViewerForm = new FormDataViewer(dataReceiver);
            dataViewerForm.Show();
        }

        private void OnExit(object sender, EventArgs e)
        {
            // Limpar recursos
            trayIcon.Visible = false;
            checkTimer.Dispose();

            // Fechar o aplicativo
            Application.Exit();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                // Limpar recursos
                trayIcon.Dispose();
                checkTimer.Dispose();
            }

            base.Dispose(disposing);
        }
    }
}
