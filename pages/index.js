import { useState } from 'react';
import Head from 'next/head';
import styles from '../styles/Home.module.css';

export default function Home() {
  const [pin, setPin] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Limpar mensagens anteriores
    setMessage('');
    setError('');
    setSuccess(false);
    
    // Validar entrada
    if (!pin || pin.length !== 4 || !/^\d+$/.test(pin)) {
      setError('O PIN deve ter exatamente 4 dígitos');
      return;
    }
    
    if (!name || name.trim().length < 2) {
      setError('Por favor, insira um nome válido');
      return;
    }
    
    try {
      setLoading(true);
      
      // Enviar dados para a API
      const response = await fetch('/api/data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          PIN: pin,
          Name: name,
        }),
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || 'Erro ao enviar dados');
      }
      
      // Sucesso
      setSuccess(true);
      setMessage('Dados enviados com sucesso! O aplicativo Windows processará esses dados.');
      
      // Limpar formulário
      setPin('');
      setName('');
    } catch (err) {
      console.error('Erro:', err);
      setError(err.message || 'Ocorreu um erro ao enviar os dados');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Formulário de PIN</title>
        <meta name="description" content="Formulário para envio de PIN e nome" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>Formulário de PIN</h1>

        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.formGroup}>
            <label htmlFor="pin">PIN (4 dígitos):</label>
            <input
              type="text"
              id="pin"
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              maxLength={4}
              pattern="\\d{4}"
              disabled={loading}
              className={styles.input}
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="name">Nome:</label>
            <input
              type="text"
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={loading}
              className={styles.input}
            />
          </div>

          <button 
            type="submit" 
            disabled={loading} 
            className={styles.button}
          >
            {loading ? 'Enviando...' : 'Send'}
          </button>
        </form>

        {error && (
          <div className={styles.error}>
            Erro ao executar a automação. Detalhes: {error}
          </div>
        )}

        {success && message && (
          <div className={styles.success}>
            {message}
          </div>
        )}
      </main>
    </div>
  );
}
