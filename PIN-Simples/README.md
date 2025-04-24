# PIN Automação - Modo Webhook

Este aplicativo monitora automaticamente novos dados e executa a automação quando recebe dados.

## Como Usar

1. Execute o arquivo:
   ```
   PIN-Automacao.bat
   ```

2. O aplicativo irá:
   - Verificar se o Node.js está instalado
   - Verificar se o Puppeteer está instalado e instalá-lo se necessário
   - Iniciar o monitoramento automático da API
   - Executar a automação automaticamente quando receber novos dados
   - Repetir a verificação a cada 30 segundos

3. Para interromper o aplicativo:
   - Pressione Ctrl+C no console

## Requisitos

- Node.js (versão 14 ou superior)
- Conexão com a internet

## Logs e Screenshots

Todos os logs e screenshots são salvos em:
```
%APPDATA%\PINReceiverApp\
```

- `pin-receiver.log`: Logs do receptor de PIN
- `puppeteer-automation.log`: Logs da automação
- `screenshots\`: Pasta com screenshots de cada etapa da automação
