import { useState } from 'react';
import Head from 'next/head';
import styles from '../styles/Home.module.css';

export default function Home() {
  const [pin, setPin] = useState('');
  const [name, setName] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!pin || !name) {
      setMessage('Por favor, preencha todos os campos.');
      return;
    }
    
    setLoading(true);
    setMessage('');
    
    try {
      const response = await fetch('/api/data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ pin, name }),
      });
      
      const data = await response.json();
      
      if (data.success) {
        setMessage('Dados enviados com sucesso!');
        setPin('');
        setName('');
      } else {
        setMessage('Erro ao enviar dados: ' + data.error);
      }
    } catch (error) {
      setMessage('Erro ao enviar dados: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>PIN Pairing</title>
        <meta name="description" content="PIN Pairing Application" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>
          PIN Pairing
        </h1>

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
          
          <button 
            type="submit" 
            className={styles.button}
            disabled={loading}
          >
            {loading ? 'Enviando...' : 'Enviar'}
          </button>
          
          {message && (
            <p className={styles.message}>
              {message}
            </p>
          )}
        </form>
      </main>
    </div>
  );
}
