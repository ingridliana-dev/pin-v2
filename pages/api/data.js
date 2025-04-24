// API para receber e armazenar dados de PIN
// Armazena os dados em memória (para fins de demonstração)
import fetch from "node-fetch";

let data = [];
let nextId = 1;

// URL fixa do webhook local
const WEBHOOK_URL = "http://localhost:8081";

// Função para enviar dados para o webhook local
async function sendToWebhook(pin, name) {
  try {
    console.log(`Enviando dados para webhook: PIN=${pin}, Nome=${name}`);
    const response = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ pin, name }),
      timeout: 5000, // 5 segundos de timeout
    });

    if (!response.ok) {
      console.error(
        `Erro ao enviar para webhook: ${response.status} ${response.statusText}`
      );
      return false;
    }

    console.log("Dados enviados com sucesso para o webhook");
    return true;
  } catch (error) {
    console.error("Erro ao enviar para webhook:", error.message);
    return false;
  }
}

export default function handler(req, res) {
  // Permitir CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  // Lidar com requisições OPTIONS (preflight)
  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  // Obter parâmetros da consulta
  const { since, processed, markProcessed, single, id } = req.query;

  // Adicionar novo item (POST)
  if (req.method === "POST") {
    try {
      const { pin, name } = req.body;

      if (!pin || !name) {
        res.status(400).json({ error: "PIN e Nome são obrigatórios" });
        return;
      }

      const newItem = {
        id: nextId++,
        pin,
        name,
        timestamp: new Date().toISOString(),
        processed: false,
      };

      data.push(newItem);

      // Enviar dados para o webhook local automaticamente
      sendToWebhook(pin, name)
        .then((success) => {
          console.log(`Webhook notificado: ${success ? "Sucesso" : "Falha"}`);
        })
        .catch((error) => {
          console.error("Erro ao notificar webhook:", error);
        });

      res.status(200).json({
        success: true,
        item: newItem,
        webhookNotified: true,
      });
    } catch (error) {
      console.error("Erro na API:", error);
      res.status(500).json({ error: error.message });
    }
    return;
  }

  // Marcar item como processado
  if (markProcessed === "true") {
    try {
      let itemIndex = -1;

      // Encontrar o item pelo ID (prioridade) ou pelo timestamp
      if (id) {
        itemIndex = data.findIndex(
          (item) => item.id === parseInt(id) && !item.processed
        );
      } else if (since) {
        itemIndex = data.findIndex(
          (item) => item.timestamp === since && !item.processed
        );
      }

      if (itemIndex !== -1) {
        data[itemIndex].processed = true;
        res.status(200).json({ success: true, item: data[itemIndex] });
      } else {
        res.status(404).json({ error: "Item not found" });
      }
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
    return;
  }

  // Filtrar dados com base nos parâmetros
  let filteredData = [...data];

  // Filtrar por data
  if (since) {
    const sinceDate = new Date(since);
    filteredData = filteredData.filter(
      (item) => new Date(item.timestamp) > sinceDate
    );
  }

  // Filtrar por status de processamento
  if (processed === "true") {
    filteredData = filteredData.filter((item) => item.processed);
  } else if (processed === "false") {
    filteredData = filteredData.filter((item) => !item.processed);
  }

  // Retornar apenas um item se solicitado
  if (single === "true" && filteredData.length > 0) {
    res.status(200).json(filteredData[0]);
  } else {
    res.status(200).json(filteredData);
  }
}
