# Receptor de PIN - Aplicativo Windows

Este aplicativo roda em segundo plano no Windows e recebe dados do formulário web em https://pin-v2-six.vercel.app/.

## Funcionalidades

- Execução em segundo plano com ícone na bandeja do sistema
- Verificação periódica de novos dados do formulário
- Notificação quando novos dados forem recebidos
- **Execução automática de ações quando novos dados são recebidos**
- Interface para visualizar os dados recebidos e o status da automação

## Como usar

1. Execute o arquivo `PINReceiverApp.exe`
2. O aplicativo será iniciado e ficará rodando em segundo plano
3. Um ícone será exibido na bandeja do sistema (próximo ao relógio)
4. Clique com o botão direito no ícone para acessar as opções:
   - **Verificar agora**: Verifica imediatamente se há novos dados
   - **Ver dados recebidos**: Abre uma janela com os dados recebidos
   - **Sair**: Fecha o aplicativo

## Requisitos

- Windows 7 ou superior
- .NET Framework 4.7.2 ou superior
- Conexão com a internet

## Notas

- O aplicativo armazena os dados recebidos localmente
- Os dados são mantidos mesmo após fechar o aplicativo
- O aplicativo verifica novos dados a cada 30 segundos
- A automação é executada automaticamente quando novos dados são recebidos
- O status da automação é exibido no menu de contexto e na interface de visualização de dados

## Personalização da Automação

Para personalizar as ações executadas quando novos dados são recebidos, edite o arquivo `LocalAutomation.cs`.
A classe `LocalAutomation` contém o método `ExecuteAutomationAsync` que é responsável por executar as ações desejadas.

Exemplos de automações que podem ser implementadas:

- Preencher formulários em aplicativos locais
- Executar comandos específicos
- Interagir com outros sistemas
- Enviar dados para outros aplicativos
