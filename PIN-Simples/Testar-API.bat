@echo off
color 0A
title Teste da API

echo =====================================================
echo    TESTE DA API
echo =====================================================
echo.
echo Este script ira testar se a API esta enviando dados
echo corretamente para o webhook.
echo.
echo Certifique-se de que o servidor webhook esta rodando
echo antes de executar este teste.
echo.
echo Pressione qualquer tecla para iniciar o teste...
pause > nul

echo.
echo Enviando dados de teste para a API...
echo.

REM Usar curl para enviar uma requisição POST para a API
curl -X POST -H "Content-Type: application/json" -d "{\"pin\":\"5678\",\"name\":\"Teste API\"}" https://pin-v2-six.vercel.app/api/data

echo.
echo.
echo Se o teste foi bem-sucedido, voce deve ver uma resposta
echo acima e a automacao deve iniciar automaticamente.
echo.
echo Se nao houver resposta ou ocorrer um erro, verifique se
echo o servidor webhook esta rodando corretamente.
echo.
echo =====================================================
echo.
pause
