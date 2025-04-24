// API para receber e armazenar dados de PIN
// Armazena os dados em memória (para fins de demonstração)
let data = [];
let nextId = 1;

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
      const newItem = {
        id: nextId++,
        pin: req.body.pin,
        name: req.body.name,
        timestamp: new Date().toISOString(),
        processed: false,
      };

      data.push(newItem);

      res.status(200).json({ success: true, item: newItem });
    } catch (error) {
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
