# Sistema de Formulário PIN com Automação

Este projeto implementa um sistema de formulário para coleta de PIN e nome, com automação para processar esses dados em outro computador.

## Funcionalidades

- Formulário HTML/CSS para coleta de PIN (4 dígitos) e nome
- Validação de dados no frontend e backend
- Automação com Puppeteer para processar os dados em outro sistema
- Detecção avançada de elementos na página de destino

## Configuração no Railway

Para implantar este projeto no Railway, siga estas etapas:

1. Faça fork deste repositório para sua conta do GitHub
2. Acesse o [Railway](https://railway.app/) e faça login com sua conta GitHub
3. Clique em "New Project" e selecione "Deploy from GitHub repo"
4. Selecione o repositório que você acabou de criar
5. Configure as seguintes variáveis de ambiente:
   - `PORT`: A porta em que o servidor será executado (Railway configura automaticamente)
   - `TARGET_URL`: A URL do sistema de destino (ex: "https://exemplo.com/pin#PIN")

## Variáveis de Ambiente

| Nome | Descrição | Valor Padrão |
|------|-----------|--------------|
| PORT | Porta em que o servidor será executado | 3000 |
| TARGET_URL | URL do sistema de destino para a automação | https://localhost:47990/pin#PIN |

## Desenvolvimento Local

Para executar o projeto localmente:

```bash
# Instalar dependências
npm install

# Iniciar o servidor
npm start
```

O servidor estará disponível em http://localhost:3000

## Endpoints

- `/`: Formulário principal
- `/submit`: Endpoint para envio dos dados do formulário
- `/test-automation`: Endpoint para testar a automação diretamente
- `/check-target`: Endpoint para verificar se o serviço de destino está disponível
