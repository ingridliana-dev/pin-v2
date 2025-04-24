const puppeteer = require("puppeteer");
const { program } = require("commander");

// Configurar argumentos de linha de comando
program
  .option("--pin <pin>", "PIN de 4 dígitos")
  .option("--name <name>", "Nome do usuário")
  .option("--debug", "Executar em modo de depuração")
  .parse(process.argv);

const options = program.opts();

/**
 * Executa a automação para inserir o PIN e nome no sistema
 * @param {string} pin - O PIN de 4 dígitos
 * @param {string} name - O nome do usuário
 * @param {boolean} debug - Se deve executar em modo de depuração
 */
async function runAutomation(pin, name, debug = false) {
  console.log(
    `Iniciando automação para PIN=${pin}, Nome=${name}, Debug=${debug}`
  );

  let browser;
  let logs = [];

  function log(message) {
    console.log(message);
    logs.push(message);
  }

  try {
    // Iniciar o navegador
    log("Iniciando o navegador Chrome...");

    // Configuração específica para ambiente Vercel (serverless)
    const options = {
      headless: "new", // Sempre usar modo headless
      args: [
        "--ignore-certificate-errors",
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--no-first-run",
        "--no-zygote",
        "--single-process",
      ],
      ignoreHTTPSErrors: true,
    };

    // Em ambiente de desenvolvimento local, podemos usar o Chrome instalado
    if (process.env.NODE_ENV !== "production") {
      try {
        // Tentar usar o Chrome local em ambiente de desenvolvimento
        if (process.platform === "win32") {
          options.executablePath =
            "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
        }
      } catch (e) {
        log("Não foi possível usar o Chrome local, usando o Chrome embutido");
      }
    }

    browser = await puppeteer.launch(options);

    const page = await browser.newPage();

    // Configurar timeout mais longo para navegação
    page.setDefaultNavigationTimeout(60000);

    // Configurar logs de console da página
    page.on("console", (msg) => log(`Console da página: ${msg.text()}`));

    // Capturar erros de rede
    page.on("requestfailed", (request) => {
      log(
        `Falha na requisição: ${request.url()} - ${request.failure().errorText}`
      );
    });

    // Navegar para a URL especificada
    log("Navegando para a URL...");
    try {
      // Usar a URL de destino configurada por variável de ambiente ou usar o padrão
      const targetUrl =
        process.env.TARGET_URL || "https://localhost:47990/pin#PIN";
      log(`Navegando para a URL de destino: ${targetUrl}`);
      await page.goto(targetUrl, {
        waitUntil: "networkidle2",
        timeout: 30000,
      });
      log("Navegação para a URL concluída");

      // Capturar screenshot para debug
      if (debug) {
        await page.screenshot({ path: "debug-initial-page.png" });
        log("Screenshot salvo: debug-initial-page.png");
      }

      // Verificar o conteúdo da página
      const pageContent = await page.content();
      log(`Tamanho do conteúdo da página: ${pageContent.length} caracteres`);
    } catch (navError) {
      log(`Erro na navegação inicial: ${navError.message}`);
      throw navError;
    }

    // Lidar com a página de aviso de segurança
    log("Verificando página de segurança...");
    try {
      // Verificar se estamos na página de aviso de segurança
      const advancedButtonSelector = "button#details-button";
      log(`Procurando pelo seletor: ${advancedButtonSelector}`);
      await page.waitForSelector(advancedButtonSelector, { timeout: 10000 });

      // Capturar screenshot para debug
      if (debug) {
        await page.screenshot({ path: "debug-security-page.png" });
        log("Screenshot salvo: debug-security-page.png");
      }

      // Clicar em "Avançado"
      log("Clicando em Avançado...");
      await page.click(advancedButtonSelector);

      // Clicar em "Continuar até localhost"
      log("Clicando em Continuar até localhost...");
      const proceedLinkSelector = "a#proceed-link";
      await page.waitForSelector(proceedLinkSelector, { timeout: 10000 });
      await page.click(proceedLinkSelector);
      log("Navegação pela página de segurança concluída");
    } catch (securityError) {
      log(
        `Página de aviso de segurança não encontrada ou já processada: ${securityError.message}`
      );
      // Não lançar erro aqui, pois a página de segurança pode não aparecer
    }

    // Aguardar a página de login
    log("Aguardando página de login...");
    try {
      // Capturar screenshot antes de procurar o campo de login
      if (debug) {
        await page.screenshot({ path: "debug-before-login.png" });
        log("Screenshot salvo: debug-before-login.png");
      }

      // Listar todos os inputs na página para debug
      const inputs = await page.$$eval("input", (inputs) =>
        inputs.map((input) => ({
          name: input.name,
          id: input.id,
          type: input.type,
          placeholder: input.placeholder,
        }))
      );
      log(`Inputs encontrados na página: ${JSON.stringify(inputs)}`);

      // Tentar diferentes seletores para o campo de usuário
      const usernameSelectors = [
        'input[name="username"]',
        "input#username",
        "input#usernameInput",
        'input[placeholder*="usuário"]',
        'input[placeholder*="user"]',
        'input[type="text"]',
      ];

      let usernameInput = null;
      for (const selector of usernameSelectors) {
        log(`Tentando encontrar campo de usuário com seletor: ${selector}`);
        try {
          usernameInput = await page.waitForSelector(selector, {
            timeout: 5000,
          });
          if (usernameInput) {
            log(`Campo de usuário encontrado com seletor: ${selector}`);
            break;
          }
        } catch (e) {
          log(`Seletor não encontrado: ${selector}`);
        }
      }

      if (!usernameInput) {
        throw new Error(
          "Não foi possível encontrar o campo de usuário na página"
        );
      }

      // Preencher credenciais
      log("Preenchendo credenciais...");

      // Usar diretamente o seletor que sabemos que existe
      const usernameSelector = "input#usernameInput";
      log(`Usando seletor para username: ${usernameSelector}`);

      try {
        await page.type(usernameSelector, "admin");
        log("Campo de usuário preenchido com sucesso");
      } catch (e) {
        log(`Erro ao preencher campo de usuário: ${e.message}`);
        throw e;
      }

      // Tentar diferentes seletores para o campo de senha
      const passwordSelectors = [
        'input[name="password"]',
        "input#password",
        "input#passwordInput",
        'input[type="password"]',
      ];

      let passwordInput = null;
      for (const selector of passwordSelectors) {
        log(`Tentando encontrar campo de senha com seletor: ${selector}`);
        try {
          passwordInput = await page.waitForSelector(selector, {
            timeout: 5000,
          });
          if (passwordInput) {
            log(`Campo de senha encontrado com seletor: ${selector}`);
            break;
          }
        } catch (e) {
          log(`Seletor não encontrado: ${selector}`);
        }
      }

      if (!passwordInput) {
        throw new Error(
          "Não foi possível encontrar o campo de senha na página"
        );
      }

      // Usar diretamente o seletor que sabemos que existe
      const passwordSelector = "input#passwordInput";
      log(`Usando seletor para password: ${passwordSelector}`);

      try {
        await page.type(passwordSelector, "admin");
        log("Campo de senha preenchido com sucesso");
      } catch (e) {
        log(`Erro ao preencher campo de senha: ${e.message}`);
        throw e;
      }

      // Capturar screenshot após preencher credenciais
      if (debug) {
        await page.screenshot({ path: "debug-filled-login.png" });
        log("Screenshot salvo: debug-filled-login.png");
      }

      // Clicar no botão de login
      log("Procurando botão de login...");
      const loginButtonSelectors = [
        'button[type="submit"]',
        'input[type="submit"]',
        'button:contains("Login")',
        'button:contains("Entrar")',
      ];

      let loginButton = null;
      for (const selector of loginButtonSelectors) {
        log(`Tentando encontrar botão de login com seletor: ${selector}`);
        try {
          loginButton = await page.waitForSelector(selector, { timeout: 5000 });
          if (loginButton) {
            log(`Botão de login encontrado com seletor: ${selector}`);
            break;
          }
        } catch (e) {
          log(`Seletor não encontrado: ${selector}`);
        }
      }

      if (!loginButton) {
        throw new Error(
          "Não foi possível encontrar o botão de login na página"
        );
      }

      log("Fazendo login...");
      await loginButton.click();
    } catch (loginError) {
      log(`Erro ao processar página de login: ${loginError.message}`);
      throw loginError;
    }

    // Aguardar navegação após o login
    log("Aguardando navegação após o login...");
    try {
      await page.waitForNavigation({
        waitUntil: "networkidle2",
        timeout: 30000,
      });
      log("Navegação após login concluída");

      // Capturar screenshot após login
      if (debug) {
        await page.screenshot({ path: "debug-after-login.png" });
        log("Screenshot salvo: debug-after-login.png");
      }
    } catch (navError) {
      log(`Erro na navegação após login: ${navError.message}`);
      // Continuar mesmo se houver erro, pois a página pode não redirecionar
    }

    // Clicar em "PIN Pairing"
    log("Navegando para PIN Pairing...");
    try {
      // Listar todos os links na página para debug
      const links = await page.$$eval("a", (links) =>
        links.map((link) => ({
          text: link.textContent,
          href: link.href,
        }))
      );
      log(`Links encontrados na página: ${JSON.stringify(links)}`);

      const pinPairingSelectors = [
        'a[href*="pin-pairing"]',
        'a[href*="pin#PIN"]',
        'a:contains("PIN Pairing")',
        'button:contains("PIN Pairing")',
        'a:contains("PIN")',
        'button:contains("PIN")',
      ];

      let pinPairingElement = null;
      // Navegar diretamente para a URL do PIN Pairing
      log("Navegando diretamente para a URL do PIN Pairing...");
      try {
        // Navegar diretamente para a URL do PIN Pairing
        const targetUrl =
          process.env.TARGET_URL || "https://localhost:47990/pin#PIN";
        await page.goto(targetUrl, {
          waitUntil: "networkidle2",
        });
        log("Navegação direta para PIN Pairing concluída");
        pinPairingElement = true; // Apenas para indicar que conseguimos navegar
      } catch (e) {
        log(`Erro ao navegar diretamente para PIN Pairing: ${e.message}`);

        // Tentar encontrar o link como fallback
        log("Tentando encontrar link PIN Pairing como fallback...");

        try {
          // Listar todos os links na página para debug
          const links = await page.evaluate(() => {
            return Array.from(document.querySelectorAll("a")).map((a) => ({
              text: a.textContent.trim(),
              href: a.href,
            }));
          });

          log(`Links encontrados na página: ${JSON.stringify(links)}`);

          // Tentar clicar no link com texto "PIN Pairing"
          const pinPairingLinkIndex = await page.evaluate(() => {
            const links = Array.from(document.querySelectorAll("a"));
            for (let i = 0; i < links.length; i++) {
              if (
                links[i].textContent.trim() === "PIN Pairing" ||
                links[i].href.includes("pin#PIN")
              ) {
                return i;
              }
            }
            return -1;
          });

          if (pinPairingLinkIndex >= 0) {
            log(`Link PIN Pairing encontrado no índice ${pinPairingLinkIndex}`);
            await page.evaluate((index) => {
              document.querySelectorAll("a")[index].click();
            }, pinPairingLinkIndex);
            log("Clique no link PIN Pairing realizado via evaluate");
            pinPairingElement = true;
          } else {
            log("Link PIN Pairing não encontrado via evaluate");

            // Tentar os seletores normais como último recurso
            for (const selector of pinPairingSelectors) {
              log(
                `Tentando encontrar link PIN Pairing com seletor: ${selector}`
              );
              try {
                pinPairingElement = await page.waitForSelector(selector, {
                  timeout: 5000,
                });
                if (pinPairingElement) {
                  log(`Link PIN Pairing encontrado com seletor: ${selector}`);
                  await pinPairingElement.click();
                  break;
                }
              } catch (e) {
                log(`Seletor não encontrado: ${selector}`);
              }
            }
          }
        } catch (evalError) {
          log(
            `Erro ao tentar encontrar link via evaluate: ${evalError.message}`
          );
        }
      }

      if (!pinPairingElement) {
        throw new Error(
          "Não foi possível encontrar o link PIN Pairing na página"
        );
      }

      // Não precisamos clicar se já navegamos diretamente
      if (pinPairingElement !== true) {
        await pinPairingElement.click();
        log("Clique no link PIN Pairing realizado");
      } else {
        log("Já estamos na página de PIN Pairing, não é necessário clicar");
      }
    } catch (pinPairingError) {
      log(`Erro ao navegar para PIN Pairing: ${pinPairingError.message}`);
      throw pinPairingError;
    }

    // Aguardar a página de PIN Pairing carregar
    log("Aguardando página de PIN Pairing carregar...");
    await page.waitForTimeout(3000);

    // Capturar screenshot da página de PIN Pairing
    if (debug) {
      await page.screenshot({ path: "debug-pin-pairing.png" });
      log("Screenshot salvo: debug-pin-pairing.png");
    }

    // Preencher o PIN e o nome
    log("Preenchendo PIN e nome...");
    try {
      // Listar todos os inputs na página para debug
      const inputs = await page.$$eval("input", (inputs) =>
        inputs.map((input) => ({
          name: input.name,
          id: input.id,
          type: input.type,
          placeholder: input.placeholder,
        }))
      );
      log(`Inputs encontrados na página: ${JSON.stringify(inputs)}`);

      // Vamos pular a busca por seletores e usar diretamente o que sabemos que existe
      log("Usando diretamente o seletor conhecido para o campo de PIN");

      // Simular que encontramos o campo
      let pinInput = true;

      // Usar diretamente o seletor que sabemos que existe
      const pinSelector = "input#pin-input";
      log(`Usando seletor para PIN: ${pinSelector}`);

      try {
        await page.type(pinSelector, pin);
        log("Campo de PIN preenchido com sucesso");
      } catch (e) {
        log(`Erro ao preencher campo de PIN: ${e.message}`);
        throw e;
      }

      // Vamos pular a busca por seletores e usar diretamente o que sabemos que existe
      log("Usando diretamente o seletor conhecido para o campo de nome");

      // Simular que encontramos o campo
      let nameInput = true;

      // Usar diretamente o seletor que sabemos que existe
      const nameSelector = "input#name-input";
      log(`Usando seletor para nome: ${nameSelector}`);

      try {
        await page.type(nameSelector, name);
        log("Campo de nome preenchido com sucesso");
      } catch (e) {
        log(`Erro ao preencher campo de nome: ${e.message}`);
        throw e;
      }

      // Capturar screenshot após preencher os campos
      if (debug) {
        await page.screenshot({ path: "debug-filled-pin-form.png" });
        log("Screenshot salvo: debug-filled-pin-form.png");
      }
    } catch (fillError) {
      log(`Erro ao preencher campos de PIN e nome: ${fillError.message}`);
      throw fillError;
    }

    // Enviar o formulário
    log("Enviando formulário...");
    try {
      // Primeiro, vamos tentar uma abordagem direta para o botão azul "Send"
      log("Tentando clicar diretamente no botão azul 'Send'...");

      // Capturar screenshot para debug
      if (debug) {
        await page.screenshot({ path: "debug-before-clicking-send.png" });
        log("Screenshot salvo: debug-before-clicking-send.png");
      }

      // Tentar clicar diretamente no botão azul usando uma abordagem mais específica
      const clickedBlueButton = await page.evaluate(() => {
        // Função para verificar se um elemento é azul
        function isBlueButton(button) {
          const style = window.getComputedStyle(button);
          const bgColor = style.backgroundColor.toLowerCase();
          const color = style.color.toLowerCase();
          const borderColor = style.borderColor.toLowerCase();
          const className = (button.className || "").toLowerCase();

          // Verificar se alguma propriedade contém "blue" ou cores azuis comuns
          return (
            bgColor.includes("blue") ||
            bgColor.includes("rgb(0, 0, 255)") ||
            bgColor.includes("rgb(0, 122, 255)") ||
            bgColor.includes("rgb(33, 150, 243)") ||
            color.includes("blue") ||
            borderColor.includes("blue") ||
            className.includes("blue") ||
            className.includes("primary")
          );
        }

        // Encontrar todos os botões
        const allButtons = Array.from(document.querySelectorAll("button"));
        console.log(
          "Todos os botões:",
          allButtons.map((b) => ({
            text: b.textContent.trim(),
            class: b.className,
            style: b.getAttribute("style"),
            bgColor: window.getComputedStyle(b).backgroundColor,
          }))
        );

        // Tentar encontrar um botão azul com texto "Send"
        let sendButton = allButtons.find(
          (btn) => btn.textContent.trim() === "Send" && isBlueButton(btn)
        );

        // Se não encontrar, procurar qualquer botão azul
        if (!sendButton) {
          sendButton = allButtons.find((btn) => isBlueButton(btn));
        }

        // Se ainda não encontrar, procurar qualquer botão com texto "Send"
        if (!sendButton) {
          sendButton = allButtons.find(
            (btn) =>
              btn.textContent.trim() === "Send" ||
              btn.textContent.trim().toLowerCase().includes("send")
          );
        }

        // Se encontrou algum botão, clicar nele
        if (sendButton) {
          console.log(
            "Botão encontrado:",
            sendButton.textContent,
            sendButton.className
          );
          sendButton.click();
          return true;
        }

        // Se não encontrou nenhum botão, tentar clicar no segundo botão (geralmente é o "Send")
        if (allButtons.length > 1) {
          console.log("Clicando no segundo botão:", allButtons[1].textContent);
          allButtons[1].click();
          return true;
        }

        return false;
      });

      if (clickedBlueButton) {
        log("Botão azul 'Send' encontrado e clicado com sucesso");
        return; // Sair da função se conseguimos clicar no botão
      }

      // Se não conseguimos clicar diretamente, tentar com seletores
      log("Tentando com seletores padrão...");
      const submitButtonSelectors = [
        'button[type="submit"]',
        'button:contains("Enviar")',
        'button:contains("Pair")',
        'button:contains("Submit")',
        'button:contains("Send")',
        'input[type="submit"]',
        "button",
      ];

      let submitButton = null;
      for (const selector of submitButtonSelectors) {
        log(`Tentando encontrar botão de envio com seletor: ${selector}`);
        try {
          submitButton = await page.waitForSelector(selector, {
            timeout: 5000,
          });
          if (submitButton) {
            log(`Botão de envio encontrado com seletor: ${selector}`);
            break;
          }
        } catch (e) {
          log(`Seletor não encontrado: ${selector}`);
        }
      }

      if (!submitButton) {
        log("Botão de envio não encontrado, tentando abordagem alternativa...");

        // Tentar encontrar todos os botões na página
        const buttons = await page.$$eval("button", (buttons) =>
          buttons.map((button) => ({
            text: button.textContent.trim(),
            id: button.id,
            className: button.className,
          }))
        );

        log(`Botões encontrados na página: ${JSON.stringify(buttons)}`);

        // Tentar encontrar e clicar no botão "Send" pelo texto
        try {
          log("Tentando encontrar e clicar no botão azul 'Send'...");

          // Capturar screenshot para debug antes de procurar o botão
          if (debug) {
            await page.screenshot({ path: "debug-before-send-button.png" });
            log("Screenshot salvo: debug-before-send-button.png");
          }

          // Tentar encontrar o botão azul com texto "Send"
          const sendButtonClicked = await page.evaluate(() => {
            // Procurar por todos os botões na página
            const allButtons = Array.from(document.querySelectorAll("button"));

            // Log de todos os botões encontrados para debug
            console.log(
              "Botões encontrados:",
              allButtons.map((b) => ({
                text: b.textContent.trim(),
                class: b.className,
                style: b.getAttribute("style"),
                id: b.id,
                color: window.getComputedStyle(b).backgroundColor,
              }))
            );

            // Procurar pelo botão azul com texto "Send"
            // Primeiro tentamos encontrar pelo texto exato
            let sendButton = allButtons.find(
              (btn) => btn.textContent.trim() === "Send"
            );

            // Se não encontrar pelo texto exato, procurar por botões azuis
            if (!sendButton) {
              sendButton = allButtons.find((btn) => {
                const style = window.getComputedStyle(btn);
                const bgColor = style.backgroundColor;
                const hasBlueColor =
                  bgColor.includes("rgb(0, 0, 255)") || // azul puro
                  bgColor.includes("rgb(0, 122, 255)") || // azul iOS
                  bgColor.includes("rgb(33, 150, 243)") || // azul material
                  bgColor.includes("rgb(66, 133, 244)") || // azul Google
                  bgColor.includes("rgb(0, 120, 212)") || // azul Microsoft
                  bgColor.includes("blue") ||
                  btn.className.toLowerCase().includes("blue") ||
                  btn.className.toLowerCase().includes("primary");

                return (
                  hasBlueColor &&
                  (btn.textContent.trim().toLowerCase().includes("send") ||
                    btn.textContent.trim().toLowerCase().includes("pair") ||
                    btn.textContent.trim().toLowerCase().includes("submit"))
                );
              });
            }

            // Se ainda não encontrou, procurar por qualquer botão com texto "Send"
            if (!sendButton) {
              sendButton = allButtons.find((btn) =>
                btn.textContent.trim().toLowerCase().includes("send")
              );
            }

            // Se encontrou algum botão, clicar nele
            if (sendButton) {
              console.log(
                "Botão Send encontrado:",
                sendButton.textContent,
                sendButton.className
              );
              sendButton.click();
              return true;
            }

            return false;
          });

          if (sendButtonClicked) {
            log("Botão 'Send' encontrado e clicado com sucesso via evaluate");
          } else {
            // Tentar uma abordagem mais direta - clicar em qualquer botão azul
            log(
              "Botão 'Send' não encontrado, tentando abordagem alternativa com seletores CSS..."
            );

            try {
              // Tentar encontrar botões azuis usando seletores CSS
              const blueButtonSelectors = [
                "button.blue",
                "button.primary",
                "button.btn-primary",
                "button.send-button",
                'button[style*="blue"]',
                'button[style*="rgb(0, 0, 255)"]',
                'button[style*="rgb(33, 150, 243)"]',
              ];

              let blueButtonFound = false;

              for (const selector of blueButtonSelectors) {
                log(`Tentando encontrar botão azul com seletor: ${selector}`);
                try {
                  const blueButton = await page.$(selector);
                  if (blueButton) {
                    log(`Botão azul encontrado com seletor: ${selector}`);
                    await blueButton.click();
                    blueButtonFound = true;
                    break;
                  }
                } catch (e) {
                  log(`Erro ao tentar seletor ${selector}: ${e.message}`);
                }
              }

              if (!blueButtonFound) {
                // Se ainda não encontrou, tentar clicar no botão pelo índice
                log(
                  "Tentando clicar no botão pelo índice (geralmente o segundo botão é o 'Send')..."
                );
                await page.evaluate(() => {
                  const buttons = document.querySelectorAll("button");
                  // Geralmente o segundo botão é o "Send" (índice 1)
                  if (buttons.length > 1) {
                    console.log(
                      "Clicando no segundo botão:",
                      buttons[1].textContent
                    );
                    buttons[1].click();
                  } else if (buttons.length > 0) {
                    console.log(
                      "Clicando no primeiro botão:",
                      buttons[0].textContent
                    );
                    buttons[0].click();
                  }
                });
                log("Clique no botão pelo índice realizado");
              }
            } catch (e) {
              log(`Erro na abordagem alternativa: ${e.message}`);

              // Último recurso: clicar no primeiro botão disponível
              log(
                "Tentando clicar no primeiro botão disponível como último recurso..."
              );
              await page.evaluate(() => {
                const buttons = document.querySelectorAll("button");
                if (buttons.length > 0) buttons[0].click();
              });
              log("Clique no primeiro botão realizado via evaluate");
            }
          }
        } catch (e) {
          log(`Erro ao tentar clicar no botão: ${e.message}`);

          // Tentar enviar o formulário diretamente
          try {
            log("Tentando enviar o formulário diretamente...");
            await page.evaluate(() => {
              const form = document.querySelector("form");
              if (form) form.submit();
            });
            log("Formulário enviado diretamente via evaluate");
          } catch (formError) {
            log(`Erro ao enviar formulário diretamente: ${formError.message}`);
            throw new Error(
              "Não foi possível encontrar o botão de envio na página"
            );
          }
        }
      } else {
        await submitButton.click();
        log("Clique no botão de envio realizado");
      }
    } catch (submitError) {
      log(`Erro ao enviar formulário: ${submitError.message}`);
      throw submitError;
    }

    // Aguardar confirmação
    log("Aguardando confirmação...");
    await page.waitForTimeout(3000);

    // Capturar screenshot final
    if (debug) {
      await page.screenshot({ path: "debug-final.png" });
      log("Screenshot salvo: debug-final.png");
    }

    log("Automação concluída com sucesso!");
    return { success: true, logs };
  } catch (error) {
    console.error("Erro durante a automação:", error);
    // Capturar screenshot do erro
    if (browser) {
      try {
        const pages = await browser.pages();
        if (pages.length > 0) {
          await pages[0].screenshot({ path: "error-screenshot.png" });
          log("Screenshot de erro salvo: error-screenshot.png");
        }
      } catch (e) {
        log(`Erro ao capturar screenshot de erro: ${e.message}`);
      }
    }
    return {
      success: false,
      error: error.message,
      logs,
    };
  } finally {
    // Fechar o navegador após alguns segundos para permitir visualização em modo debug
    if (browser) {
      const timeout = debug ? 30000 : 5000;
      setTimeout(async () => {
        try {
          await browser.close();
          log("Navegador fechado.");
        } catch (e) {
          log(`Erro ao fechar navegador: ${e.message}`);
        }
      }, timeout);
    }
  }
}

// Executar a automação se chamado diretamente (não como módulo)
if (require.main === module) {
  // Verificar se os parâmetros necessários foram fornecidos
  if (!options.pin || !options.name) {
    console.error("Erro: PIN e nome são obrigatórios");
    console.error(
      'Uso: node automation.js --pin 1234 --name "Nome do Usuário" [--debug]'
    );
    process.exit(1);
  }

  // Executar a automação
  runAutomation(options.pin, options.name, options.debug || false)
    .then((result) => {
      if (result.success) {
        console.log("Automação concluída com sucesso!");
        process.exit(0);
      } else {
        console.error(`Erro na automação: ${result.error}`);
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error(`Erro não tratado: ${error.message}`);
      process.exit(1);
    });
} else {
  // Exportar a função para uso como módulo
  module.exports = { runAutomation };
}
