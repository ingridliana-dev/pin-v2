using System;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;

namespace PINReceiverApp
{
    public partial class FormDataViewer : Form
    {
        private PINDataReceiver dataReceiver;
        private ListView listViewData;
        private Button btnRefresh;

        public FormDataViewer(PINDataReceiver receiver)
        {
            dataReceiver = receiver;
            InitializeComponent();
            LoadData();
        }

        private void InitializeComponent()
        {
            this.Text = "Dados de PIN Recebidos";
            this.Size = new Size(600, 400);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Icon = SystemIcons.Application;

            // Criar ListView
            listViewData = new ListView
            {
                Dock = DockStyle.Fill,
                View = View.Details,
                FullRowSelect = true,
                GridLines = true
            };

            // Adicionar colunas
            listViewData.Columns.Add("PIN", 80);
            listViewData.Columns.Add("Nome", 150);
            listViewData.Columns.Add("Data/Hora de Recebimento", 150);
            listViewData.Columns.Add("Status da Automação", 150);
            listViewData.Columns.Add("Automação Concluída em", 150);

            // Criar botão de atualização
            btnRefresh = new Button
            {
                Text = "Atualizar",
                Dock = DockStyle.Bottom,
                Height = 30
            };
            btnRefresh.Click += BtnRefresh_Click;

            // Adicionar controles ao formulário
            this.Controls.Add(listViewData);
            this.Controls.Add(btnRefresh);

            // Configurar evento de fechamento
            this.FormClosing += FormDataViewer_FormClosing;
        }

        private void LoadData()
        {
            listViewData.Items.Clear();
            List<PINData> allData = dataReceiver.GetAllData();

            // Ordenar por data de recebimento (mais recente primeiro)
            allData.Sort((a, b) => b.ReceivedAt.CompareTo(a.ReceivedAt));

            foreach (var data in allData)
            {
                ListViewItem item = new ListViewItem(data.PIN);
                item.SubItems.Add(data.Name);
                item.SubItems.Add(data.ReceivedAt.ToString("dd/MM/yyyy HH:mm:ss"));
                item.SubItems.Add(data.AutomationStatus ?? "Não iniciada");
                item.SubItems.Add(data.AutomationCompletedAt.HasValue
                    ? data.AutomationCompletedAt.Value.ToString("dd/MM/yyyy HH:mm:ss")
                    : "-");

                // Colorir a linha de acordo com o status da automação
                if (data.AutomationStatus != null)
                {
                    if (data.AutomationStatus.StartsWith("Concluída"))
                    {
                        item.BackColor = Color.LightGreen;
                    }
                    else if (data.AutomationStatus.StartsWith("Falhou") || data.AutomationStatus.StartsWith("Erro"))
                    {
                        item.BackColor = Color.LightPink;
                    }
                    else
                    {
                        item.BackColor = Color.LightYellow; // Em andamento
                    }
                }

                listViewData.Items.Add(item);
            }
        }

        private void BtnRefresh_Click(object sender, EventArgs e)
        {
            LoadData();
        }

        private void FormDataViewer_FormClosing(object sender, FormClosingEventArgs e)
        {
            // Apenas esconder o formulário em vez de fechá-lo
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;
                this.Hide();
            }
        }
    }
}
