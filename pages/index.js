import { useState, useEffect } from "react";
import Head from "next/head";
import styles from "../styles/Home.module.css";

export default function Home() {
  const [pin, setPin] = useState("");
  const [name, setName] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [webhookUrl, setWebhookUrl] = useState("http://localhost:8080");

  // Carregar a URL do webhook do localStorage
  useEffect(() => {
    const savedUrl = localStorage.getItem("webhookUrl");
    if (savedUrl) {
      setWebhookUrl(savedUrl);
    }
  }, []);

  // Salvar a URL do webhook no localStorage
  const saveWebhookUrl = () => {
    if (webhookUrl) {
      localStorage.setItem("webhookUrl", webhookUrl);
      setMessage("URL do webhook salva com sucesso!");
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!pin || !name) {
      setMessage("Por favor, preencha todos os campos.");
      return;
    }

    setLoading(true);
    setMessage("");

    try {
      // Sempre usar o endpoint de webhook
      const endpoint = "/api/webhook";

      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          pin,
          name,
          // Sempre incluir a URL do webhook
          webhookUrl,
        }),
      });

      const data = await response.json();

      if (data.success) {
        setMessage("Dados enviados com sucesso!");
        setPin("");
        setName("");
      } else {
        setMessage("Erro ao enviar dados: " + data.error);
      }
    } catch (error) {
      setMessage("Erro ao enviar dados: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>PIN Pairing</title>
        <meta name="description" content="PIN Pairing Application" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
        />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>PIN Pairing</h1>

        <p className={styles.description}>
          Preencha os campos abaixo para enviar um PIN
        </p>

        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.formGroup}>
            <label htmlFor="pin">PIN:</label>
            <input
              type="text"
              id="pin"
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              placeholder="Digite o PIN"
              required
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="name">Nome:</label>
            <input
              type="text"
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Digite seu nome"
              required
            />
          </div>

          <div className={styles.webhookSection}>
            <div className={styles.webhookUrl}>
              <label htmlFor="webhookUrl">
                Configuração do Webhook (Execução Imediata):
              </label>
              <div className={styles.webhookUrlInput}>
                <input
                  type="text"
                  id="webhookUrl"
                  value={webhookUrl}
                  onChange={(e) => setWebhookUrl(e.target.value)}
                  placeholder="http://localhost:8080"
                />
                <button
                  type="button"
                  onClick={saveWebhookUrl}
                  className={styles.saveButton}
                >
                  Salvar
                </button>
              </div>
              <p className={styles.webhookHelp}>
                Para execução imediata, execute o arquivo PIN-Webhook.bat no seu
                computador.
              </p>
            </div>
          </div>

          <button type="submit" className={styles.button} disabled={loading}>
            {loading ? "Enviando..." : "Enviar"}
          </button>

          {message && <p className={styles.message}>{message}</p>}
        </form>
      </main>
    </div>
  );
}
