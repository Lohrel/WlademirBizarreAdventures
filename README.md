# 🧛‍♂️ Wlademir Bizarre Adventures

Um **Dungeon Crawler Procedural** atmosférico desenvolvido na **Godot Engine 4**.

## 📖 Premissa
Wlademir, um vampiro ancestral, desperta em ruínas egípcias esquecidas. Sua missão é encontrar a cura para sua maldição antes que os ciclos implacáveis do sol o transformem em cinzas. Explore um labirinto que se reconstrói a cada tentativa, onde a luz é sua maior inimiga e as sombras sua única aliada.

---

## 🛠️ Mecânicas Implementadas (Protótipo)

### 🌓 Ciclo Celestial Dinâmico
- **Sol Senoidal**: O sol cruza as salas de teto aberto em uma linha reta (Oeste para Leste), variando de intensidade e projetando sombras dinâmicas.
- **Intervalo de Crepúsculo**: Momentos de escuridão total entre o pôr do sol e o nascer da lua.
- **Luar Azul**: Uma luz suave que ilumina sem ferir, acompanhada de poeira azulada.
- **Vagalumes Mascarados**: Enxames noturnos que brilham apenas quando tocados pela luz celestial, pulsando organicamente.

### 🏛️ Geração Procedural
- **Caminhada Aleatória**: Salas geradas dinamicamente em uma grade de 400x400 pixels.
- **Decoração Inteligente**: Pilastras e caixas nascem em posições aleatórias, respeitando áreas de luz e passagens de portas.
- **Paredes Dinâmicas**: Salas detectam vizinhos para abrir caminhos ou fechar fronteiras automaticamente.

### 📦 Física e Exploração
- **Objetos Empurráveis**: Caixas com massa e atrito calculados (RigidBody2D) que o jogador pode mover para abrir caminho ou criar abrigo.
- **Câmera Suave**: Sistema de interpolação (lerp) para seguir o protagonista com fluidez.

---

## 🎨 Guia para o Artista

### 📁 Estrutura de Pastas
- `assets/sprites/`: Todos os arquivos `.png` ou `.svg`.
- `scenes/`: Peças do jogo (Salas, Player, Itens).
- `scripts/`: Lógica em GDScript.

### 📏 Especificações Técnicas
- **Resolução de Tela**: 640x360 (Escalável para Fullscreen).
- **Tamanho Base**: 32x32 pixels (Wlademir e Tiles).
- **Filtro de Textura**: Linear (para suavização de luzes).

### 💡 Dica sobre Luzes
O jogo utiliza **Iluminação Dinâmica 2D**. Se você criar sprites com fundos transparentes, eles reagirão automaticamente às sombras e ao brilho do sol/lua.

---

## 🎮 Controles
- **WASD / Setas**: Movimentação.
- **F11**: Alternar Fullscreen.
- **F5**: Reiniciar Labirinto (Reset Procedural).

---

## 🚀 Como Contribuir
1. Dê um `git pull origin main` no terminal ou GitHub Desktop.
2. Adicione suas artes em `assets/sprites/`.
3. Teste o jogo na Godot (F5) para garantir que nada quebrou.
4. Salve seu progresso: `git add .` -> `git commit -m "Descrição"` -> `git push origin main`.
