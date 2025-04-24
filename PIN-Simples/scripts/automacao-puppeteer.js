// Script simplificado para automação com Puppeteer
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// Configuração de linha de comando
const args = process.argv.slice(2);
let pin = '1234';
let name = 'Teste';
let debug = true;

// Processar argumentos
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--pin' && i + 1 < args.length) {
    pin = args[i + 1];
    i++;
  } else if (args[i] === '--name' && i + 1 < args.length) {
    name = args[i + 1];
    i++;
  } else if (args[i] === '--debug') {
    debug = true;
  }
}

// Configurar pasta de logs
const appDataDir = process.env.APPDATA || (process.platform === 'darwin' ? 
  path.join(process.env.HOME, 'Library', 'Application Support') : 
  path.join(process.env.HOME, '.local', 'share'));
const logDir = path.join(appDataDir, 'PINReceiverApp');

// Criar pasta de logs se não existir
try {
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
} catch (err) {
  console.error(`Erro ao criar diretório de logs: ${err.message}`);
}

const logFile = path.join(logDir, 'puppeteer-automation.log');
const screenshotDir = path.join(logDir, 'screenshots');

// Criar pasta de screenshots se não existir
try {
  if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
  }
} catch (err) {
  console.error(`Erro ao criar diretório de screenshots: ${err.message}`);
}

// Função para registrar logs
function log(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}`;
  console.log(logMessage);
  
  try {
    fs.appendFileSync(logFile, logMessage + '\n');
  } catch (err) {
    console.error(`Erro ao escrever no arquivo de log: ${err.message}`);
  }
}

// Função para capturar screenshot
async function takeScreenshot(page, name) {
  try {
    const screenshotPath = path.join(screenshotDir, `${name}-${Date.now()}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    log(`Screenshot salvo em: ${screenshotPath}`);
  } catch (err) {
    log(`Erro ao capturar screenshot: ${err.message}`);
  }
}

// Função principal
async function run() {
  log(`Iniciando automação com Puppeteer`);
  log(`PIN: ${pin}, Nome: ${name}, Debug: ${debug}`);
  
  let browser = null;
  
  try {
    // Configurações do navegador - SEMPRE visível
    const launchOptions = {
      headless: false, // Garantir que o navegador seja visível
      args: [
        '--window-size=1280,720',
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--ignore-certificate-errors',
      ],
      ignoreHTTPSErrors: true,
      defaultViewport: { width: 1280, height: 720 }
    };
    
    log('Iniciando navegador...');
    browser = await puppeteer.launch(launchOptions);
    log('Navegador iniciado com sucesso');
    
    const page = await browser.newPage();
    log('Nova página aberta');
    
    // Configurar timeout mais longo
    page.setDefaultNavigationTimeout(60000);
    page.setDefaultTimeout(30000);
    
    // Capturar logs do console
    page.on('console', msg => log(`Console do navegador: ${msg.text()}`));
    
    // Capturar erros de rede
    page.on('requestfailed', request => {
      log(`Falha na requisição: ${request.url()} - ${request.failure().errorText}`);
    });
    
    // Navegar para a URL
    const url = 'https://localhost:47990/pin#PIN';
    log(`Navegando para: ${url}`);
    
    await page.goto(url, { waitUntil: 'networkidle2' });
    log('Página carregada');
    await takeScreenshot(page, 'inicial');
    
    // Verificar se estamos na página de aviso de segurança
    log('Verificando página de segurança...');
    try {
      // Tentar encontrar o botão "Avançado"
      const detailsButton = await page.$('button#details-button');
      if (detailsButton) {
        log('Página de segurança detectada, clicando em "Avançado"');
        await detailsButton.click();
        await page.waitForTimeout(1000);
        
        // Clicar em "Continuar para o site"
        const proceedLink = await page.$('a#proceed-link');
        if (proceedLink) {
          log('Clicando em "Continuar para o site"');
          await proceedLink.click();
          await page.waitForNavigation({ waitUntil: 'networkidle2' });
        }
      }
    } catch (err) {
      log(`Não foi possível processar a página de segurança: ${err.message}`);
      // Continuar mesmo se não encontrar a página de segurança
    }
    
    // Verificar se estamos na página de login
    log('Verificando página de login...');
    await takeScreenshot(page, 'apos-seguranca');
    
    try {
      // Tentar encontrar campos de login
      const usernameInput = await page.$('#usernameInput');
      if (usernameInput) {
        log('Página de login detectada, preenchendo credenciais');
        await usernameInput.type('admin');
        log('Nome de usuário preenchido');
        
        const passwordInput = await page.$('#passwordInput');
        if (passwordInput) {
          await passwordInput.type('admin');
          log('Senha preenchida');
          
          // Procurar botão de login
          const loginButton = await page.$('button[type="submit"]');
          if (loginButton) {
            log('Clicando no botão de login');
            await loginButton.click();
            await page.waitForNavigation({ waitUntil: 'networkidle2' }).catch(e => {
              log(`Aviso: Timeout na navegação após login: ${e.message}`);
            });
          } else {
            log('Botão de login não encontrado, tentando pressionar Enter');
            await page.keyboard.press('Enter');
            await page.waitForNavigation({ waitUntil: 'networkidle2' }).catch(e => {
              log(`Aviso: Timeout na navegação após login: ${e.message}`);
            });
          }
        }
      } else {
        log('Campos de login não encontrados, assumindo que já estamos logados');
      }
    } catch (err) {
      log(`Erro ao processar login: ${err.message}`);
      // Continuar mesmo se houver erro no login
    }
    
    // Aguardar um pouco para garantir que a página carregou
    await page.waitForTimeout(3000);
    await takeScreenshot(page, 'apos-login');
    
    // Verificar se estamos na página de PIN
    log('Verificando página de PIN...');
    
    try {
      // Tentar encontrar o campo de PIN
      const pinInput = await page.$('#pin-input');
      if (pinInput) {
        log(`Campo de PIN encontrado, preenchendo com: ${pin}`);
        await pinInput.type(pin);
        
        // Tentar encontrar o campo de nome
        const nameInput = await page.$('#name-input');
        if (nameInput) {
          log(`Campo de nome encontrado, preenchendo com: ${name}`);
          await nameInput.type(name);
          
          // Capturar screenshot antes de enviar
          await takeScreenshot(page, 'formulario-preenchido');
          
          // Procurar botão de envio
          const submitButton = await page.$('button[type="submit"]');
          if (submitButton) {
            log('Clicando no botão de envio');
            await submitButton.click();
          } else {
            log('Botão de envio não encontrado, tentando pressionar Enter');
            await page.keyboard.press('Enter');
          }
          
          // Aguardar um pouco para ver o resultado
          await page.waitForTimeout(5000);
          await takeScreenshot(page, 'apos-envio');
          
          log('Formulário enviado com sucesso');
        } else {
          log('Campo de nome não encontrado');
          throw new Error('Campo de nome não encontrado');
        }
      } else {
        log('Campo de PIN não encontrado');
        throw new Error('Campo de PIN não encontrado');
      }
    } catch (err) {
      log(`Erro ao preencher formulário: ${err.message}`);
      await takeScreenshot(page, 'erro');
      throw err;
    }
    
    log('Automação concluída com sucesso!');
    return true;
  } catch (err) {
    log(`ERRO: ${err.message}`);
    log(`Stack trace: ${err.stack}`);
    return false;
  } finally {
    // Manter o navegador aberto por um tempo para visualização
    if (browser) {
      log('Mantendo navegador aberto por 30 segundos para visualização...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      try {
        log('Fechando navegador...');
        await browser.close();
        log('Navegador fechado');
      } catch (err) {
        log(`Erro ao fechar navegador: ${err.message}`);
      }
    }
  }
}

// Executar a função principal
run()
  .then(success => {
    if (success) {
      log('Processo concluído com sucesso');
      process.exit(0);
    } else {
      log('Processo concluído com erros');
      process.exit(1);
    }
  })
  .catch(err => {
    log(`Erro fatal: ${err.message}`);
    process.exit(1);
  });
