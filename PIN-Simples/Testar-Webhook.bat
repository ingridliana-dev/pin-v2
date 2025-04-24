@echo off
color 0A
title Teste do Webhook

echo =====================================================
echo    TESTE DO WEBHOOK
echo =====================================================
echo.
echo Este script ira testar se o servidor webhook esta
echo funcionando corretamente.
echo.
echo Certifique-se de que o servidor webhook esta rodando
echo antes de executar este teste.
echo.
echo Pressione qualquer tecla para iniciar o teste...
pause > nul

echo.
echo Enviando dados de teste para o webhook...
echo.

REM Usar curl para enviar uma requisição POST para o webhook
curl -X POST -H "Content-Type: application/json" -d "{\"pin\":\"1234\",\"name\":\"Teste\"}" http://localhost:8081

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
