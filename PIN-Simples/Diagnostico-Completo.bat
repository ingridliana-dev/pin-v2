@echo off
color 0A
title Diagnostico Completo

echo =====================================================
echo    DIAGNOSTICO COMPLETO
echo =====================================================
echo.
echo Este script ira realizar um diagnostico completo do
echo sistema de automacao.
echo.
echo Pressione qualquer tecla para iniciar...
pause > nul

echo.
echo 1. Verificando se a porta 8080 esta aberta...
echo.

REM Verificar se a porta 8080 está em uso
netstat -ano | findstr :8080
if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] A porta 8080 esta em uso.
) else (
    color 0C
    echo.
    echo [ERRO] A porta 8080 NAO esta em uso!
    echo O servidor webhook provavelmente nao esta rodando.
    echo.
    echo Execute o arquivo PIN-Servidor.bat ou PIN-Invisivel.vbs
    echo para iniciar o servidor webhook.
    echo.
    echo Diagnostico interrompido. Corrija o problema e tente novamente.
    pause
    exit /b 1
)

echo.
echo 2. Verificando se o servidor webhook responde...
echo.

REM Verificar se podemos acessar o servidor
curl -s -o nul -w "%%{http_code}" http://localhost:8080
if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] O servidor webhook esta respondendo.
) else (
    color 0E
    echo.
    echo [AVISO] A porta esta em uso, mas nao conseguimos acessar o servidor.
    echo Isso pode indicar um problema de firewall ou permissoes.
)

echo.
echo 3. Testando envio direto para o webhook...
echo.

REM Usar curl para enviar uma requisição POST para o webhook
curl -X POST -H "Content-Type: application/json" -d "{\"pin\":\"1234\",\"name\":\"Teste Diagnostico\"}" http://localhost:8080

echo.
echo.
echo 4. Testando conexao com a API...
echo.

REM Verificar se podemos acessar a API
curl -s -o nul -w "%%{http_code}" https://pin-v2-six.vercel.app/api/data
if %ERRORLEVEL% equ 0 (
    echo.
    echo [OK] A API esta acessivel.
) else (
    color 0E
    echo.
    echo [AVISO] Nao conseguimos acessar a API.
    echo Isso pode indicar um problema de conexao com a internet.
)

echo.
echo 5. Testando envio para a API...
echo.

REM Usar curl para enviar uma requisição POST para a API
curl -X POST -H "Content-Type: application/json" -d "{\"pin\":\"5678\",\"name\":\"Teste API Diagnostico\"}" https://pin-v2-six.vercel.app/api/data

echo.
echo.
echo =====================================================
echo DIAGNOSTICO CONCLUIDO
echo =====================================================
echo.
echo Verifique os resultados acima para identificar possiveis
echo problemas. Se a automacao nao estiver funcionando, verifique:
echo.
echo 1. O servidor webhook esta rodando?
echo 2. O firewall esta permitindo conexoes na porta 8080?
echo 3. A conexao com a internet esta funcionando?
echo 4. A API esta enviando dados corretamente?
echo.
echo =====================================================
echo.
pause
