@echo off
color 0A
title Atualizar API com URL do Ngrok

echo =====================================================
echo    ATUALIZAR API COM URL DO NGROK
echo =====================================================
echo.
echo Este script ira atualizar a API com a URL do ngrok.
echo.
echo IMPORTANTE: Voce precisa ter iniciado o ngrok primeiro!
echo.
echo Pressione qualquer tecla para continuar...
pause > nul

REM Verificar se o arquivo com a URL do ngrok existe
if not exist "PIN-Simples\tools\ngrok_url.txt" (
    color 0C
    echo.
    echo ERRO: Arquivo com URL do ngrok nao encontrado!
    echo Por favor, execute o script Iniciar-Ngrok.bat primeiro.
    echo.
    pause
    exit /b 1
)

REM Ler a URL do arquivo
set /p NGROK_URL=<PIN-Simples\tools\ngrok_url.txt

REM Verificar se a URL foi lida corretamente
if "%NGROK_URL%"=="" (
    color 0C
    echo.
    echo ERRO: Nao foi possivel ler a URL do ngrok!
    echo Por favor, execute o script Iniciar-Ngrok.bat novamente.
    echo.
    pause
    exit /b 1
)

echo.
echo URL do ngrok: %NGROK_URL%
echo.
echo Atualizando a API...

REM Criar um arquivo temporário com o código atualizado
echo // API para receber e armazenar dados de PIN> temp_api.js
echo // Armazena os dados em memória (para fins de demonstração)>> temp_api.js
echo import fetch from "node-fetch";>> temp_api.js
echo.>> temp_api.js
echo let data = [];>> temp_api.js
echo let nextId = 1;>> temp_api.js
echo.>> temp_api.js
echo // URL do webhook (ngrok)>> temp_api.js
echo const WEBHOOK_URL = "%NGROK_URL%";>> temp_api.js
echo.>> temp_api.js
echo // Função para enviar dados para o webhook local>> temp_api.js
echo async function sendToWebhook(pin, name) {>> temp_api.js
echo   try {>> temp_api.js
echo     console.log(`Enviando dados para webhook: PIN=${pin}, Nome=${name}`);>> temp_api.js
echo     const response = await fetch(WEBHOOK_URL, {>> temp_api.js
echo       method: "POST",>> temp_api.js
echo       headers: {>> temp_api.js
echo         "Content-Type": "application/json",>> temp_api.js
echo       },>> temp_api.js
echo       body: JSON.stringify({ pin, name }),>> temp_api.js
echo       timeout: 5000, // 5 segundos de timeout>> temp_api.js
echo     });>> temp_api.js
echo.>> temp_api.js
echo     if (!response.ok) {>> temp_api.js
echo       console.error(>> temp_api.js
echo         `Erro ao enviar para webhook: ${response.status} ${response.statusText}`>> temp_api.js
echo       );>> temp_api.js
echo       return false;>> temp_api.js
echo     }>> temp_api.js
echo.>> temp_api.js
echo     console.log("Dados enviados com sucesso para o webhook");>> temp_api.js
echo     return true;>> temp_api.js
echo   } catch (error) {>> temp_api.js
echo     console.error("Erro ao enviar para webhook:", error.message);>> temp_api.js
echo     return false;>> temp_api.js
echo   }>> temp_api.js
echo }>> temp_api.js
echo.>> temp_api.js
echo export default function handler(req, res) {>> temp_api.js
echo   // Permitir CORS>> temp_api.js
echo   res.setHeader("Access-Control-Allow-Origin", "*");>> temp_api.js
echo   res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");>> temp_api.js
echo   res.setHeader("Access-Control-Allow-Headers", "Content-Type");>> temp_api.js
echo.>> temp_api.js
echo   // Lidar com requisições OPTIONS (preflight)>> temp_api.js
echo   if (req.method === "OPTIONS") {>> temp_api.js
echo     res.status(200).end();>> temp_api.js
echo     return;>> temp_api.js
echo   }>> temp_api.js
echo.>> temp_api.js
echo   // Obter parâmetros da consulta>> temp_api.js
echo   const { since, processed, markProcessed, single, id } = req.query;>> temp_api.js
echo.>> temp_api.js
echo   // Adicionar novo item (POST)>> temp_api.js
echo   if (req.method === "POST") {>> temp_api.js
echo     try {>> temp_api.js
echo       const { pin, name } = req.body;>> temp_api.js
echo.>> temp_api.js
echo       if (!pin || !name) {>> temp_api.js
echo         res.status(400).json({ error: "PIN e Nome são obrigatórios" });>> temp_api.js
echo         return;>> temp_api.js
echo       }>> temp_api.js
echo.>> temp_api.js
echo       const newItem = {>> temp_api.js
echo         id: nextId++,>> temp_api.js
echo         pin,>> temp_api.js
echo         name,>> temp_api.js
echo         timestamp: new Date().toISOString(),>> temp_api.js
echo         processed: false,>> temp_api.js
echo       };>> temp_api.js
echo.>> temp_api.js
echo       data.push(newItem);>> temp_api.js
echo.>> temp_api.js
echo       // Enviar dados para o webhook local automaticamente>> temp_api.js
echo       sendToWebhook(pin, name)>> temp_api.js
echo         .then((success) => {>> temp_api.js
echo           console.log(`Webhook notificado: ${success ? "Sucesso" : "Falha"}`);>> temp_api.js
echo         })>> temp_api.js
echo         .catch((error) => {>> temp_api.js
echo           console.error("Erro ao notificar webhook:", error);>> temp_api.js
echo         });>> temp_api.js
echo.>> temp_api.js
echo       res.status(200).json({>> temp_api.js
echo         success: true,>> temp_api.js
echo         item: newItem,>> temp_api.js
echo         webhookNotified: true,>> temp_api.js
echo       });>> temp_api.js
echo     } catch (error) {>> temp_api.js
echo       console.error("Erro na API:", error);>> temp_api.js
echo       res.status(500).json({ error: error.message });>> temp_api.js
echo     }>> temp_api.js
echo     return;>> temp_api.js
echo   }>> temp_api.js
echo.>> temp_api.js
echo   // Marcar item como processado>> temp_api.js
echo   if (markProcessed === "true") {>> temp_api.js
echo     try {>> temp_api.js
echo       let itemIndex = -1;>> temp_api.js
echo.>> temp_api.js
echo       // Encontrar o item pelo ID (prioridade) ou pelo timestamp>> temp_api.js
echo       if (id) {>> temp_api.js
echo         itemIndex = data.findIndex(>> temp_api.js
echo           (item) => item.id === parseInt(id) && !item.processed>> temp_api.js
echo         );>> temp_api.js
echo       } else if (since) {>> temp_api.js
echo         itemIndex = data.findIndex(>> temp_api.js
echo           (item) => item.timestamp === since && !item.processed>> temp_api.js
echo         );>> temp_api.js
echo       }>> temp_api.js
echo.>> temp_api.js
echo       if (itemIndex !== -1) {>> temp_api.js
echo         data[itemIndex].processed = true;>> temp_api.js
echo         res.status(200).json({ success: true, item: data[itemIndex] });>> temp_api.js
echo       } else {>> temp_api.js
echo         res.status(404).json({ error: "Item not found" });>> temp_api.js
echo       }>> temp_api.js
echo     } catch (error) {>> temp_api.js
echo       res.status(500).json({ error: error.message });>> temp_api.js
echo     }>> temp_api.js
echo     return;>> temp_api.js
echo   }>> temp_api.js
echo.>> temp_api.js
echo   // Filtrar dados com base nos parâmetros>> temp_api.js
echo   let filteredData = [...data];>> temp_api.js
echo.>> temp_api.js
echo   // Filtrar por data>> temp_api.js
echo   if (since) {>> temp_api.js
echo     const sinceDate = new Date(since);>> temp_api.js
echo     filteredData = filteredData.filter(>> temp_api.js
echo       (item) => new Date(item.timestamp) > sinceDate>> temp_api.js
echo     );>> temp_api.js
echo   }>> temp_api.js
echo.>> temp_api.js
echo   // Filtrar por status de processamento>> temp_api.js
echo   if (processed === "true") {>> temp_api.js
echo     filteredData = filteredData.filter((item) => item.processed);>> temp_api.js
echo   } else if (processed === "false") {>> temp_api.js
echo     filteredData = filteredData.filter((item) => !item.processed);>> temp_api.js
echo   }>> temp_api.js
echo.>> temp_api.js
echo   // Retornar apenas um item se solicitado>> temp_api.js
echo   if (single === "true" && filteredData.length > 0) {>> temp_api.js
echo     res.status(200).json(filteredData[0]);>> temp_api.js
echo   } else {>> temp_api.js
echo     res.status(200).json(filteredData);>> temp_api.js
echo   }>> temp_api.js
echo }>> temp_api.js

REM Copiar o arquivo temporário para o arquivo da API
copy /y temp_api.js pages\api\data.js > nul
del temp_api.js

echo.
echo API atualizada com sucesso!
echo.
echo Agora voce precisa fazer o commit e push das alteracoes:
echo.
echo git add pages/api/data.js
echo git commit -m "Atualiza API para usar ngrok"
echo git push
echo.
echo =====================================================
echo.
pause
