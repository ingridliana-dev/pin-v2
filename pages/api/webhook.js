// API para enviar dados diretamente para o webhook
import fetch from 'node-fetch';

export default async function handler(req, res) {
  // Permitir CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Lidar com requisições OPTIONS (preflight)
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Apenas aceitar POST
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { pin, name, webhookUrl } = req.body;
    
    if (!pin || !name) {
      res.status(400).json({ error: 'PIN and name are required' });
      return;
    }

    // Salvar os dados na API principal
    const apiUrl = `${process.env.NEXT_PUBLIC_API_URL || 'https://pin-v2-six.vercel.app'}/api/data`;
    const saveResponse = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ pin, name }),
    });

    const saveData = await saveResponse.json();
    
    // Se um URL de webhook foi fornecido, enviar os dados diretamente para ele
    if (webhookUrl) {
      try {
        const webhookResponse = await fetch(webhookUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ pin, name }),
        });
        
        if (!webhookResponse.ok) {
          console.error(`Webhook error: ${webhookResponse.status} ${webhookResponse.statusText}`);
        }
      } catch (webhookError) {
        console.error('Error sending to webhook:', webhookError);
      }
    }

    res.status(200).json({ 
      success: true, 
      message: 'Data saved and webhook notified',
      item: saveData.item 
    });
  } catch (error) {
    console.error('Webhook API error:', error);
    res.status(500).json({ error: error.message });
  }
}
