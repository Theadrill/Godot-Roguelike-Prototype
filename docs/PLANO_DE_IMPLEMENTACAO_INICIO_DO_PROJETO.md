# Plano de Implementação — Início do Projeto (Severed Dawn)

Este documento estabelece as fases atômicas de engenharia para construir a fundação física e o núcleo de combate de **Severed Dawn** no padrão *Greybox / Whitebox Prototype*.

> [!IMPORTANT]
> ## REGRA DE OURO DAS FASES
> Cada fase deve ser concluída com **validação headless limpa** (`godot --headless --check-only`), testada com o controle e homologada pelo PO antes de avançar para a próxima fase.
> **Parada Crítica:** Sempre que for necessário gerar qualquer sprite visual, a IA deve parar e perguntar ao PO antes de criar a imagem.

---

## 🏗️ Fase 0: Scaffold do Projeto Godot 4 & Input Map

### 1. Objetivo
Criar a fundação estrutural do projeto Godot 4 com arquitetura limpa de diretórios, configurações de viewport pixel-perfect e mapeamento universal de controles (Teclado + Gamepad).

### 2. Entregáveis
* `project.godot` configurado:
  * Resolução interna: **640 × 360** (modo `viewport`, aspecto `canvas_items`).
  * Texturas: filtro `nearest` (sem borrões em 1080p/1440p/4K).
  * Gravidade global e física 2D calibradas.
  * **Input Map Oficial**:
    * `move_left`: A, Seta Esquerda, D-Pad Esquerdo, Analógico Esquerdo.
    * `move_right`: D, Seta Direita, D-Pad Direito, Analógico Esquerdo.
    * `down`: S, Seta Baixo, D-Pad Baixo, Analógico Esquerdo para baixo.
    * `jump`: Barra de Espaço, Botão A (Xbox) / X (PlayStation).
    * `roll`: Shift Esquerdo, Botão B (Xbox) / Círculo (PlayStation).
    * `attack`: Botão Esquerdo do Mouse, Botão X (Xbox) / Quadrado (PlayStation).
* Árvore de diretórios criada:
  * `src/core/`: Classes base (`state.gd`, `state_machine.gd`).
  * `src/entities/player/`: Cena e scripts da FSM do protagonista.
  * `src/entities/enemies/`: Dummies de teste e inimigos.
  * `src/world/`: Cenas de teste, ginásio e chunks.
  * `assets/`: Texturas e shaders futuros.

### 3. Critério de Aceite
* O projeto abre na Godot 4 sem avisos e valida com sucesso no terminal (`godot --headless --check-only --path .`).

---

## 🥋 Fase 1: O "Movement Gym" (A Sala de Ginástica da Física)

### 1. Objetivo
Construir a sala de testes de movimentação e implementar a Máquina de Estados Finita (FSM) modular do protagonista em *greybox* (usando colisão geométrica exata de 16 × 40 px), validando o *game feel* de Dead Cells.

### 2. Entregáveis
* **Cena de Teste (`src/world/movement_gym.tscn`)**:
  * Chão plano reto para aceleração e parada seca.
  * Parede lisa para teste de *Wall-Slide* e *Wall-Jump*.
  * Degrau de **4 tiles (64 px)**: validação do 1º pulo.
  * Degrau de **7 tiles (112 px)**: validação do pulo duplo.
  * Fosso de **4 tiles (64 px)**: validação do *coyote time* no limite da borda.
  * Teto baixo de **2 tiles (32 px)**: validação da passagem com rolamento.
* **FSM do Jogador (`src/entities/player/`)**:
  * `IdleState`: Parada seca e suporte preparado para variações.
  * `RunState`: Aceleração ágil em 0.08s.
  * `JumpState`: Salto de impulso fixo de 4 tiles.
  * `DoubleJumpState`: Salto secundário de +3 tiles.
  * `FallState`: Gravidade acelerada (1.3x) + *Coyote Time* (0.12s) + *Jump Buffer* (0.12s).
  * `WallSlideState` & `WallJumpState`: Deslize e repulsão diagonal com trava de input de 0.1s.
  * `RollState`: Arrancada com invulnerabilidade total (i-frames).
* **Câmera 2D Fluida**:
  * `Camera2D` suave acompanhando o jogador com amortecimento (*lerp*) e *look-ahead*.

### 3. Critério de Aceite
* O PO roda o jogo com o controle na mão e atesta que o boneco responde de forma rápida, pesada e precisa em todos os obstáculos da sala de ginástica.

---

## 🥊 Fase 2: O "Combat Dummy" (O Boneco de Pancada & Impacto)

### 1. Objetivo
Implementar o golpe básico de espada no jogador e um boneco de treino para calibrar a sensação física de impacto (*hitstop*, recuo e resposta tátil no controle).

### 2. Entregáveis
* `AttackState` na FSM do jogador com hitbox ativada nos frames ativos.
* `HurtboxArea` e script de Dummy com reação a dano.
* **Micro-Hitstop (0.05s)** no impacto.
* **Vibração Tátil no Gamepad** via API nativa da Godot 4.
* **Knockback Físico** proporcional à arma equipada via `WeaponData`.
* Shaders de *Hit-Flash* branco no alvo.

### 3. Critério de Aceite
* Cada golpe no dummy transmite peso físico nas mãos do PO através do gamepad e da parada de frames.

---

## ⚔️ Fase 3: O Inimigo com os Sinais Táticos (Amarelo / Vermelho)

### 1. Objetivo
Dar vida ao inimigo de teste para disparar golpes com sinalização visual e validar o cancelamento de ataques (*stunlock*).

### 2. Entregáveis
* Inimigo básico com patrulha e ciclo de ataque.
* Cancelamento imediato de golpe se o jogador atacar primeiro (*Zero Hyper-Armor*).
* Sinal Amarelo (pesado/ininterruptível) e Vermelho (perilous).
* Esquiva via Rolamento para evitar o dano.

### 3. Critério de Aceite
* O combate 1v1 parece justo, fluido e punitivo, recompensando a iniciativa do jogador.
