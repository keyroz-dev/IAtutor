// Mensagem de boas-vindas
window.addEventListener('DOMContentLoaded', () => {
    console.log("Bem-vindo ao IA Tutor de Inglês!");
});

// Botão para voltar ao topo
const backToTopButton = document.createElement('button');
backToTopButton.textContent = '↑ Topo';
backToTopButton.id = 'back-to-top';
backToTopButton.style.cssText = `
    position: fixed;
    bottom: 30px;
    right: 30px;
    padding: 10px 15px;
    font-size: 16px;
    border: none;
    background-color: #333;
    color: white;
    border-radius: 8px;
    cursor: pointer;
    display: none;
    z-index: 1000;
`;
document.body.appendChild(backToTopButton);

window.addEventListener('scroll', () => {
    if (window.scrollY > 300) {
        backToTopButton.style.display = 'block';
    } else {
        backToTopButton.style.display = 'none';
    }
});

backToTopButton.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
});

