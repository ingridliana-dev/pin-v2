using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Text.Json;
using System.IO;
using System.Windows.Forms;

namespace PINReceiverApp
{
    public class PINDataReceiver
    {
        private readonly HttpClient httpClient;
        private readonly string apiUrl = "https://pin-v2-six.vercel.app/api/data";
        private readonly string dataFilePath;
        private List<PINData> receivedData;
        private DateTime lastCheckTime;
        private LocalAutomation automation;

        // Evento para notificar quando novos dados são recebidos
        public event EventHandler<PINData> NewDataReceived;

        // Evento para notificar sobre o progresso da automação
        public event EventHandler<string> AutomationProgressUpdated;

        public PINDataReceiver()
        {
            httpClient = new HttpClient();

            // Configurar o caminho para o arquivo de dados
            string appDataFolder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "PINReceiverApp"
            );

            // Criar a pasta se não existir
            if (!Directory.Exists(appDataFolder))
            {
                Directory.CreateDirectory(appDataFolder);
            }

            dataFilePath = Path.Combine(appDataFolder, "received_data.json");

            // Carregar dados existentes
            receivedData = LoadData();

            // Inicializar o tempo da última verificação
            lastCheckTime = DateTime.Now.AddMinutes(-5); // Verificar dados dos últimos 5 minutos no início

            // Inicializar a automação local
            automation = new LocalAutomation();
            automation.AutomationProgressUpdated += (sender, message) =>
            {
                // Repassar eventos de progresso da automação
                AutomationProgressUpdated?.Invoke(this, message);
            };
        }

        public async Task<PINData> CheckForNewDataAsync()
        {
            try
            {
                // Construir a URL com o timestamp da última verificação
                string url = $"{apiUrl}?since={Uri.EscapeDataString(lastCheckTime.ToString("o"))}";

                // Atualizar o timestamp para a próxima verificação
                lastCheckTime = DateTime.Now;

                // Fazer a requisição HTTP
                HttpResponseMessage response = await httpClient.GetAsync(url);

                // Verificar se a requisição foi bem-sucedida
                if (response.IsSuccessStatusCode)
                {
                    string jsonContent = await response.Content.ReadAsStringAsync();
                    var data = JsonSerializer.Deserialize<PINData>(jsonContent);

                    // Se recebemos dados válidos, adicionar à lista e salvar
                    if (data != null && !string.IsNullOrEmpty(data.PIN))
                    {
                        data.ReceivedAt = DateTime.Now;
                        receivedData.Add(data);
                        SaveData();

                        // Notificar que novos dados foram recebidos
                        NewDataReceived?.Invoke(this, data);

                        // Executar a automação local com os novos dados
                        await ExecuteLocalAutomationAsync(data);

                        return data;
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao verificar novos dados: {ex.Message}");
                AutomationProgressUpdated?.Invoke(this, $"Erro ao verificar novos dados: {ex.Message}");
                return null;
            }
        }

        // Método para executar a automação local
        private async Task ExecuteLocalAutomationAsync(PINData data)
        {
            try
            {
                // Executar a automação com os dados recebidos
                bool success = await automation.ExecuteAutomationAsync(data.PIN, data.Name);

                // Atualizar o status da automação nos dados
                data.AutomationStatus = success ? "Concluída com sucesso" : "Falhou";
                data.AutomationCompletedAt = DateTime.Now;

                // Salvar os dados atualizados
                SaveData();
            }
            catch (Exception ex)
            {
                // Registrar erro na automação
                AutomationProgressUpdated?.Invoke(this, $"Erro na automação local: {ex.Message}");

                // Atualizar o status da automação nos dados
                data.AutomationStatus = $"Erro: {ex.Message}";
                SaveData();
            }
        }

        public List<PINData> GetAllData()
        {
            return new List<PINData>(receivedData);
        }

        private List<PINData> LoadData()
        {
            try
            {
                if (File.Exists(dataFilePath))
                {
                    string json = File.ReadAllText(dataFilePath);
                    return JsonSerializer.Deserialize<List<PINData>>(json) ?? new List<PINData>();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao carregar dados: {ex.Message}");
            }

            return new List<PINData>();
        }

        private void SaveData()
        {
            try
            {
                string json = JsonSerializer.Serialize(receivedData, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(dataFilePath, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao salvar dados: {ex.Message}");
            }
        }
    }

    public class PINData
    {
        public string PIN { get; set; }
        public string Name { get; set; }
        public DateTime ReceivedAt { get; set; }
        public string AutomationStatus { get; set; }
        public DateTime? AutomationCompletedAt { get; set; }
    }
}
