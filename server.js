const express = require("express");
const path = require("path");
const bodyParser = require("body-parser");
const fs = require("fs");
const { runAutomation } = require("./automation");

const app = express();
const PORT = process.env.PORT || 3000;

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

    // Executar a automação
    try {
      const result = await runAutomation(pin, name);
      if (result.success) {
        res.json({
          message: "Dados enviados com sucesso! A automação foi iniciada.",
          logs: result.logs,
        });
      } else {
        res.status(500).json({
          message: "Erro ao executar a automação. Detalhes: " + result.error,
          logs: result.logs,
        });
      }
    } catch (error) {
      console.error("Erro na automação:", error);
      res.status(500).json({
        message: "Erro ao executar a automação. Detalhes: " + error.message,
      });
    }
  } catch (error) {
    console.error("Erro no servidor:", error);
    res.status(500).json({ message: "Erro interno do servidor." });
  }
});

// Rota para testar a automação diretamente (apenas para debug)
app.get("/test-automation", async (req, res) => {
  try {
    const pin = req.query.pin || "1234";
    const name = req.query.name || "Teste";
    const debug = req.query.debug === "true";

    console.log(
      `Iniciando teste de automação com PIN=${pin}, Nome=${name}, Debug=${debug}`
    );

    // Executar a automação em modo de debug
    const result = await runAutomation(pin, name, debug);

    // Salvar logs em um arquivo para análise posterior
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const logFilename = `automation-log-${timestamp}.json`;
    fs.writeFileSync(logFilename, JSON.stringify(result, null, 2));

    res.json({
      success: result.success,
      message: result.success
        ? "Automação concluída com sucesso!"
        : "Erro na automação: " + result.error,
      logFile: logFilename,
      logs: result.logs,
    });
  } catch (error) {
    console.error("Erro ao testar automação:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao testar automação: " + error.message,
    });
  }
});

// Rota para verificar se o serviço na porta 47990 está disponível
app.get("/check-target", async (req, res) => {
  try {
    const https = require("https");
    const url = process.env.TARGET_URL || "https://localhost:47990/pin";

    // Tentar acessar a URL alvo
    const request = https.get(
      url,
      {
        rejectUnauthorized: false, // Ignorar erros de certificado
        timeout: 5000, // Timeout de 5 segundos
      },
      (response) => {
        res.json({
          available: true,
          statusCode: response.statusCode,
          message: `Serviço disponível na porta 47990 (Status: ${response.statusCode})`,
        });
      }
    );

    request.on("error", (error) => {
      res.json({
        available: false,
        error: error.message,
        message: `Serviço não disponível na porta 47990: ${error.message}`,
      });
    });

    request.on("timeout", () => {
      request.destroy();
      res.json({
        available: false,
        error: "Timeout",
        message: "Timeout ao tentar acessar o serviço na porta 47990",
      });
    });
  } catch (error) {
    res.json({
      available: false,
      error: error.message,
      message: `Erro ao verificar disponibilidade: ${error.message}`,
    });
  }
});

// Iniciar o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
  console.log(`Endpoints disponíveis:`);
  console.log(`- Formulário: http://localhost:${PORT}/`);
  console.log(
    `- Teste de automação: http://localhost:${PORT}/test-automation?pin=1234&name=Teste&debug=true`
  );
  console.log(
    `- Verificar serviço alvo: http://localhost:${PORT}/check-target`
  );
});
