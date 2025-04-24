# PIN-v2

Aplicação para pareamento de PIN com automação.

## Estrutura do Projeto

- **pages/api/data.js**: API para receber e armazenar dados de PIN
- **pages/index.js**: Página inicial com formulário para envio de PIN
- **PIN-Simples/**: Pasta com a solução de automação
  - **PIN-Automacao.bat**: Executável principal para iniciar a automação
  - **scripts/**: Scripts de automação

## Como Usar

### Frontend (Vercel)

1. Acesse a aplicação em: https://pin-v2-six.vercel.app/
2. Preencha o formulário com PIN e Nome
3. Clique em "Enviar"

### Automação (Local)

1. Clone este repositório
2. Execute o arquivo `PIN-Simples/PIN-Automacao.bat`
3. O aplicativo monitorará automaticamente novos dados e executará a automação quando receber dados

## Desenvolvimento

```bash
# Instalar dependências
npm install

# Executar em modo de desenvolvimento
npm run dev

# Construir para produção
npm run build

# Iniciar servidor de produção
npm run start
```
