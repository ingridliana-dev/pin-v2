const express = require("express");
const path = require("path");
const bodyParser = require("body-parser");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 3000;

// Armazenar dados recebidos para consulta pelo aplicativo Windows
const submittedData = [];

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Servir arquivos estáticos
app.use(express.static(path.join(__dirname)));

// Rotas específicas para arquivos estáticos (para garantir que funcionem na Vercel)
app.get("/styles.css", (req, res) => {
  res.setHeader("Content-Type", "text/css");
  res.sendFile(path.join(__dirname, "styles.css"));
});

app.get("/script.js", (req, res) => {
  res.setHeader("Content-Type", "application/javascript");
  res.sendFile(path.join(__dirname, "script.js"));
});

// Rota para servir o formulário
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Rota para receber os dados do formulário
app.post("/submit", async (req, res) => {
  try {
    const { pin, name } = req.body;

    // Validação do PIN (4 dígitos numéricos)
    if (!/^\d{4}$/.test(pin)) {
      return res
        .status(400)
        .json({ message: "O PIN deve conter exatamente 4 dígitos numéricos." });
    }

    // Validação do nome (não vazio)
    if (!name || !name.trim()) {
      return res
        .status(400)
        .json({ message: "Por favor, insira um nome válido." });
    }

    console.log(`Dados recebidos: PIN=${pin}, Nome=${name}`);

    // Armazenar os dados recebidos com timestamp
    const newData = {
      PIN: pin,
      Name: name,
      timestamp: new Date().toISOString(),
      processed: false,
    };

    submittedData.push(newData);

    // Manter apenas os últimos 100 registros para não consumir muita memória
    if (submittedData.length > 100) {
      submittedData.shift(); // Remove o registro mais antigo
    }

    // Retornar sucesso sem tentar executar automação
    res.json({
      success: true,
      message:
        "Dados enviados com sucesso! O aplicativo Windows processará esses dados.",
      data: newData,
    });
  } catch (error) {
    console.error("Erro no servidor:", error);
    res.status(500).json({ message: "Erro interno do servidor." });
  }
});

// Rota para testar a API (apenas para debug)
app.get("/test-api", (req, res) => {
  try {
    res.json({
      status: "API funcionando corretamente",
      dataCount: submittedData.length,
      timestamp: new Date().toISOString(),
      endpoints: [
        {
          method: "POST",
          path: "/submit",
          description: "Enviar dados do formulário",
        },
        {
          method: "GET",
          path: "/api/data",
          description: "Consultar dados armazenados",
        },
        {
          method: "POST",
          path: "/api/mark-processed",
          description: "Marcar dados como processados",
        },
      ],
    });
  } catch (error) {
    console.error("Erro ao testar API:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao testar API: " + error.message,
    });
  }
});

// Rota para verificar o status da API
app.get("/api/status", (req, res) => {
  try {
    res.json({
      status: "online",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
      storedDataCount: submittedData.length,
      unprocessedCount: submittedData.filter((item) => !item.processed).length,
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      error: error.message,
      message: "Erro ao verificar status da API",
    });
  }
});

// Rota para o aplicativo Windows consultar os dados
app.get("/api/data", (req, res) => {
  try {
    // Verificar se há um parâmetro 'since' na requisição
    const since = req.query.since ? new Date(req.query.since) : null;

    // Verificar se há parâmetro 'processed' para filtrar por status
    let processedFilter = undefined;
    if (req.query.processed !== undefined) {
      processedFilter = req.query.processed === "true";
    }

    // Se não houver dados, retornar array vazio
    if (submittedData.length === 0) {
      return res.json([]);
    }

    // Filtrar os dados
    let filteredData = [...submittedData];

    // Filtrar por data se o parâmetro 'since' estiver presente
    if (since) {
      filteredData = filteredData.filter((item) => {
        const itemDate = new Date(item.timestamp);
        return itemDate > since;
      });
    }

    // Filtrar por status de processamento se o parâmetro 'processed' estiver presente
    if (processedFilter !== undefined) {
      filteredData = filteredData.filter((item) => {
        return item.processed === processedFilter;
      });
    }

    // Se houver apenas um resultado e o cliente espera um único objeto
    if (filteredData.length === 1 && req.query.single === "true") {
      // Marcar como processado se solicitado
      if (req.query.markProcessed === "true") {
        const index = submittedData.findIndex(
          (item) => item.timestamp === filteredData[0].timestamp
        );
        if (index !== -1) {
          submittedData[index].processed = true;
        }
      }
      return res.json(filteredData[0]);
    }

    // Retornar todos os resultados filtrados
    return res.json(filteredData);
  } catch (error) {
    console.error("Erro ao consultar dados:", error);
    res.status(500).json({ error: "Erro ao consultar dados" });
  }
});

// Rota para o aplicativo Windows marcar dados como processados
app.post("/api/mark-processed", (req, res) => {
  try {
    const { timestamp } = req.body;

    if (!timestamp) {
      return res.status(400).json({ error: "Timestamp é obrigatório" });
    }

    // Encontrar o item pelo timestamp
    const index = submittedData.findIndex(
      (item) => item.timestamp === timestamp
    );

    if (index === -1) {
      return res.status(404).json({ error: "Dados não encontrados" });
    }

    // Marcar como processado
    submittedData[index].processed = true;

    return res.json({
      success: true,
      message: "Dados marcados como processados com sucesso",
    });
  } catch (error) {
    console.error("Erro ao marcar dados como processados:", error);
    return res.status(500).json({ error: "Erro interno do servidor" });
  }
});

// Iniciar o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
  console.log(`Endpoints disponíveis:`);
  console.log(`- Formulário: http://localhost:${PORT}/`);
  console.log(`- Enviar dados: POST http://localhost:${PORT}/submit`);
  console.log(`- Consultar dados: GET http://localhost:${PORT}/api/data`);
  console.log(
    `- Marcar como processado: POST http://localhost:${PORT}/api/mark-processed`
  );
  console.log(`- Status da API: GET http://localhost:${PORT}/api/status`);
  console.log(`- Testar API: GET http://localhost:${PORT}/test-api`);
});
