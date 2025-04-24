# Sistema de Formulário PIN com Automação Local

Este projeto implementa um sistema de formulário para coleta de PIN e nome, com um aplicativo Windows que executa automação localmente para processar esses dados.

## Funcionalidades

- Formulário web para coleta de PIN (4 dígitos) e nome
- Validação de dados no frontend e backend
- API para armazenar os dados temporariamente
- Aplicativo Windows que verifica novos dados e executa automação localmente
- Interface gráfica para visualizar os dados recebidos e o status da automação

## Implantação na Vercel

Para implantar este projeto na Vercel, siga estas etapas:

1. Faça fork deste repositório para sua conta do GitHub
2. Acesse o [Vercel](https://vercel.com/) e faça login com sua conta GitHub
3. Clique em "Add New..." e selecione "Project"
4. Selecione o repositório que você acabou de criar
5. Na tela de configuração:
   - Framework Preset: Selecione "Next.js"
   - Build Command: Deixe o padrão (npm run build)
   - Output Directory: Deixe em branco
   - Install Command: `npm install`
6. Clique em "Deploy"

## Componentes do Sistema

### 1. Formulário Web (Frontend)

- Hospedado na Vercel em https://pin-v2-six.vercel.app/
- Permite que o usuário insira um PIN de 4 dígitos e um nome
- Quando o usuário clica em "Send", os dados são enviados para a API

### 2. API (Backend)

- Também hospedada na Vercel junto com o frontend
- Apenas armazena os dados temporariamente
- Fornece endpoints para consulta e marcação de dados como processados

### 3. Aplicativo Windows (Executável Local)

- Script PowerShell (`PINReceiver.ps1`) que roda no seu computador
- Verifica periodicamente se há novos dados na API
- Quando encontra novos dados, executa a automação localmente
- Após processar, marca os dados como processados na API

## Desenvolvimento Local

Para executar o projeto localmente:

```bash
# Instalar dependências
npm install

# Iniciar o servidor
npm start
```

O servidor estará disponível em http://localhost:3000

## Endpoints da API

- `/`: Formulário principal
- `/submit`: Endpoint para envio dos dados do formulário
- `/api/data`: Endpoint para consultar dados armazenados
- `/api/mark-processed`: Endpoint para marcar dados como processados
- `/api/status`: Endpoint para verificar o status da API
- `/test-api`: Endpoint para testar a API

## Executando o Aplicativo Windows

1. Certifique-se de ter o PowerShell 5.1 ou superior instalado
2. Baixe o arquivo `PINReceiver.ps1` ou o executável `PINReceiver.exe` da pasta `Executavel`
3. Para executar o script PowerShell diretamente:
   ```powershell
   powershell -ExecutionPolicy Bypass -File PINReceiver.ps1
   ```
4. Para converter o script em um executável:

   ```powershell
   # Instalar o módulo PS2EXE (uma vez)
   Install-Module -Name PS2EXE -Scope CurrentUser -Force

   # Converter o script
   Import-Module PS2EXE
   Invoke-PS2EXE -InputFile 'PINReceiver.ps1' -OutputFile 'PINReceiver.exe' -NoConsole
   ```

5. Execute o arquivo `PINReceiver.exe` gerado
6. O aplicativo ficará rodando na bandeja do sistema (ícone perto do relógio)
7. Clique com o botão direito no ícone para ver as opções disponíveis
