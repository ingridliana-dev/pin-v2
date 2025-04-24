document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('pinForm');
    const statusDiv = document.getElementById('status');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const pin = document.getElementById('pin').value;
        const name = document.getElementById('name').value;
        
        // Validação do PIN (4 dígitos numéricos)
        if (!/^\d{4}$/.test(pin)) {
            showStatus('O PIN deve conter exatamente 4 dígitos numéricos.', 'error');
            return;
        }
        
        // Validação do nome (não vazio)
        if (!name.trim()) {
            showStatus('Por favor, insira um nome válido.', 'error');
            return;
        }
        
        try {
            showStatus('Enviando dados...', '');
            
            const response = await fetch('/submit', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ pin, name })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                showStatus(data.message, 'success');
                form.reset();
            } else {
                showStatus(data.message || 'Erro ao processar a solicitação.', 'error');
            }
        } catch (error) {
            console.error('Erro:', error);
            showStatus('Erro ao conectar com o servidor. Tente novamente mais tarde.', 'error');
        }
    });
    
    function showStatus(message, type) {
        statusDiv.textContent = message;
        statusDiv.className = 'status';
        
        if (type) {
            statusDiv.classList.add(type);
        }
    }
});
