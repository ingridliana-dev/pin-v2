=============================================
RECEPTOR DE PIN - APLICATIVO WINDOWS
=============================================

Este aplicativo roda em segundo plano no Windows e recebe dados do formulário web em https://pin-v2-six.vercel.app/.

COMO USAR:
---------
1. Execute o arquivo "PINReceiver.bat"
2. O aplicativo será iniciado e ficará rodando em segundo plano
3. Um ícone será exibido na bandeja do sistema (próximo ao relógio)
4. Clique com o botão direito no ícone para acessar as opções:
   - Verificar agora: Verifica imediatamente se há novos dados
   - Ver dados recebidos: Abre uma janela com os dados recebidos
   - Status da automação: Mostra o status atual da automação
   - Sair: Fecha o aplicativo

FUNCIONALIDADES:
--------------
- Execução em segundo plano com ícone na bandeja do sistema
- Verificação periódica de novos dados do formulário
- Notificação quando novos dados forem recebidos
- Execução automática de ações quando novos dados são recebidos
- Interface para visualizar os dados recebidos e o status da automação

REQUISITOS:
---------
- Windows 7 ou superior
- PowerShell 3.0 ou superior (já incluído no Windows 7 SP1 e posteriores)
- Conexão com a internet

NOTAS:
-----
- O aplicativo armazena os dados recebidos localmente na pasta AppData
- Os dados são mantidos mesmo após fechar o aplicativo
- O aplicativo verifica novos dados a cada 30 segundos
- A automação é executada automaticamente quando novos dados são recebidos
- Não é necessário instalar nada, basta executar o arquivo .bat
