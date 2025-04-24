// API para armazenar e recuperar dados do formulário
// Este arquivo não tenta executar automação, apenas armazena dados

// Armazenamento temporário de dados (em produção, use um banco de dados)
let storedData = [];

export default function handler(req, res) {
  // Permitir CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Lidar com requisições OPTIONS (preflight CORS)
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Processar requisição POST (envio de dados do formulário)
  if (req.method === 'POST') {
    try {
      const { PIN, Name } = req.body;
      
      // Validar dados
      if (!PIN || !Name) {
        return res.status(400).json({ error: 'PIN e Nome são obrigatórios' });
      }

      // Criar novo registro com timestamp
      const newData = {
        PIN,
        Name,
        timestamp: new Date().toISOString(),
        processed: false
      };

      // Adicionar ao armazenamento
      storedData.push(newData);
      
      // Manter apenas os últimos 100 registros para evitar consumo excessivo de memória
      if (storedData.length > 100) {
        storedData = storedData.slice(-100);
      }

      // Retornar sucesso
      return res.status(200).json({ 
        success: true, 
        message: 'Dados recebidos com sucesso',
        data: newData
      });
    } catch (error) {
      console.error('Erro ao processar dados:', error);
      return res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error.message 
      });
    }
  }

  // Processar requisição GET (consulta de dados)
  if (req.method === 'GET') {
    try {
      // Verificar se há parâmetro 'since' para filtrar por data
      const { since } = req.query;
      
      let filteredData = [...storedData];
      
      // Filtrar por data se o parâmetro 'since' estiver presente
      if (since) {
        const sinceDate = new Date(since);
        filteredData = filteredData.filter(item => {
          const itemDate = new Date(item.timestamp);
          return itemDate > sinceDate;
        });
      }

      // Verificar se há parâmetro 'processed' para filtrar por status
      if (req.query.processed !== undefined) {
        const processed = req.query.processed === 'true';
        filteredData = filteredData.filter(item => item.processed === processed);
      }

      // Se houver apenas um resultado e o cliente espera um único objeto
      if (filteredData.length === 1 && req.query.single === 'true') {
        // Marcar como processado se solicitado
        if (req.query.markProcessed === 'true') {
          const index = storedData.findIndex(item => item.timestamp === filteredData[0].timestamp);
          if (index !== -1) {
            storedData[index].processed = true;
          }
        }
        return res.status(200).json(filteredData[0]);
      }

      // Retornar todos os resultados filtrados
      return res.status(200).json(filteredData);
    } catch (error) {
      console.error('Erro ao consultar dados:', error);
      return res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error.message 
      });
    }
  }

  // Método não suportado
  res.setHeader('Allow', ['GET', 'POST', 'OPTIONS']);
  res.status(405).json({ error: `Método ${req.method} não permitido` });
}
