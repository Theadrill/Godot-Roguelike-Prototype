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

---

## 🎒 Fase 4: Arquitetura Modular de Equipamentos & Sockets (`MainHand` / `OffHand` / `BackSockets`)

### 1. Visão Geral do Escopo
Criar a fundação estrutural de encaixe de itens desacoplados do sprite base do protagonista (*Socketed Paperdoll*), evitando que equipamentos sejam desenhados colados ao corpo e conferindo uma silhueta clássica de "arsenal nas costas":
* **Pontos de Ancoragem (4 Sockets no `$Visual` do Protagonista):**
  * `MainHandSocket` (`Marker2D` em `Vector2(6, -20)`): Empunhadura ativa da arma principal (Espada, Adaga, Martelo, Cajado).
  * `OffHandSocket` (`Marker2D` em `Vector2(4, -18)`): Empunhadura ativa para o escudo em guarda/parry ou secundária em ação.
  * `BackSocketShield` (`Marker2D` em `Vector2(-4, -22)`, rotacionado `-12°`): Ponto de repouso no dorso para o escudo, mantendo-o visível nas costas durante Idle, Run, Jump e Attack.
  * `BackSocketWeapon` (`Marker2D` em `Vector2(-2, -22)`, rotacionado `+25°`): Ponto de repouso no dorso para a arma secundária em ângulo cruzado ("X" nas costas).
* **Ciclo de Estados dos Equipamentos:**
  * *Estado Repouso:* Escudo nas costas (`BackSocketShield`), arma secundária nas costas (`BackSocketWeapon`).
  * *Estado Ativo:* Ao defender (`LB`/`L1`), o escudo transiciona para a mão esquerda (`OffHandSocket`). Ao atacar/usar arma principal, ela é empunhada no `MainHandSocket`.
* **Placeholders Geométricos Simples (Regra 4 - Zero Arte Final):** Sprites/Polígonos monocromáticos minimalistas para validação de pivôs:
  * Espada (lâmina 20x4px)
  * Adaga (lâmina 10x3px)
  * Martelo (cabo 24x3px + cabeça pesada 10x12px)
  * Cajado (haste 30x3px + gema ciano)
  * Arco (haste curva de madeira flexível 36x8px + corda esticada)
  * Besta / Crossbow (coronha de madeira 20x4px + proa transversal em "T" 26x3px + estribo de ferro)
  * Escudo/Broquel (placa rústica 12x18px)
* **Diretriz de Armaduras:** Deixada para a fase final do projeto para definição madura entre trajes completos (*Dead Cells Skins*) vs. peças/sockets simplificados.

> [!NOTE]
> **Backlog Técnico de Inimigos (Anotado para Fase Futura):** O soldado de teste no `movement_gym` atualmente executa apenas golpes para cima engatilhando sempre o sinal AMARELO (ataque pesado/aparável). A rotação completa de ataques (branco/normal, amarelo/pesado e vermelho/perilous) será balanceada na fase de IA/Inimigos sem misturar com o escopo atual de sockets/combate.

> [!NOTE]
> Esta fase estrutural prepara o terreno para plugar o escudo e as próximas armas sem necessidade de refatoração futura.

---

## 🛡️ Fase 5: O Sistema de Defesa, Resposta aos 3 Sinais & Movimentação Avançada

### 1. Visão Geral do Escopo
Completar o triângulo tático de combate corpo a corpo e as manobras físicas avançadas especificadas no **Pilar 2** do Game Design Document ([`docs/BRAINSTORMING.md`](BRAINSTORMING.md)):

* **Sistema de Escudo / Defesa & Resposta aos 3 Sinais:**
  * **Bloqueio Simples:** Absorção com *chip damage* (15%) contra ataques pesados/amarelos.
  * **Parry Perfeito (Aparar):** Janela de precisão que anula 100% do dano e atordoa o inimigo (*stagger* para contra-ataque crítico).
  * **Penalidade de Quebra de Guarda:** Golpes vermelhos (*Perilous*) quebram a guarda passiva e causam 100% de dano se o jogador não esquivar ou aparar com perfeição.
* **Ground Slam (Esmagamento Descendente):**
  * Descida vertical em alta velocidade acionada no ar gerando impacto de área no solo.
* **Idle Breaks:**
  * Variações sutis de animação/pose após 5 segundos de inatividade, canceláveis no primeiro frame por qualquer input.

### 2. Decisões de Design Alinhadas com o PO (Em Andamento)
* **Ponto 1 (Controle & Layout de Combate Estrutural):** 
  * **`X` (Xbox) / `Quadrado` (PlayStation) / `Clique Esquerdo`:** Ataca com a **arma ativa atual em mãos**.
  * **`Y` (Xbox) / `Triângulo` (PlayStation) / `Clique Direito`:** **Escudo Dedicado** (sempre a postos para Guarda Contínua / Parry Perfeito). O escudo sai das costas instantaneamente para a mão esquerda.
  * **`LB` / `L1` (ou Tecla `1` no teclado):** **Troca Rápida de Arma (Weapon Swap)** — alterna imediatamente a arma ativa em mãos com a arma secundária guardada nas costas (ex: Espada ↔ Arco).
  * **`D-Pad Down` (ou Tecla `2` no teclado):** Atalho de debug para ciclar as armas de reserva disponíveis.
  * **D-Pad Desmapeado da Movimentação:** D-Pad não controla movimento analógico do herói; fica reservado para uso de itens rápidos/consumíveis no futuro.
  * O escudo é um equipamento evoluível/craftável através do irmão forjador na Casa Santuário (metaprogressão de escudos com atributos e efeitos especiais).
* **Ponto 2 (Mecânica de Toque vs. Segurar):**
  * *Toque Rápido (Tap):* Janela ativa de Parry Perfeito (~120ms).
  * *Segurar (Hold):* Guarda Contínua (absorve dano normal, 15% chip damage em amarelos, quebra de guarda em vermelhos).
* **Ponto 3 (Prevenção de Spam & Cooldown):**
  * *Punição no Erro:* Se errar o parry (apertar no ar ou fora de hora), entra em **cooldown estrito de 1.0 segundo** sem poder erguer o escudo, punindo o spam e exigindo leitura deliberada do jogador.
  * *Recompensa no Acerto:* Se acertar o parry com perfeição, o **cooldown é resetado instantaneamente**, permitindo aparar múltiplos golpes ou combos rápidos em sequência.
* **Ponto 4 (Recompensa do Parry & Modificador de Onda de Choque):**
  * *Comportamento Base Oficial:* O inimigo atacante sofre *Stun* (~0.8s a 1.0s) e o próximo golpe do jogador causa **Dano Crítico massivo** com feedback tátil no controle, mantendo a fluidez sem animação travada de riposte.
  * *Modificador de Recipe (Irmão Forjador):* Upgrade de Escudo de Repulsão — ao acertar o parry, emite uma onda de choque que afasta e repele os *demais* inimigos ao redor, isolando o jogador no 1v1 contra o alvo atordoado.
* **Ponto 5 (Representação Visual do Escudo):**
  * Opção C: Postura do corpo com braço em guarda e broquel rústico desacoplado, conectado no `OffHandSocket` criado na Fase 4.
* **Ponto 6 (Ground Slam & Reutilização Modular):**
  * *Comando:* `Baixo + Pulo` no ar.
  * *Física:* Trava horizontal no ar com velocidade vertical terminal de 850 a 1000 px/s.
  * *Impacto no Solo:* Esmagamento com dano massivo no ponto de impacto + onda de choque radial.
  * *Arquitetura Modular (`RadialShockwave`):* Criação de um componente genérico de repulsão radial compartilhado entre o *Ground Slam* (com dano de área) e o modificador de escudo do irmão (empurrão sem dano que preserva o alvo em *stun*), respeitando a **Regra 9**.
* **Ponto 7 (Idle Breaks & Zero Input Lock):**
  * *Gatilho:* 5.0 segundos de inatividade contínua no chão em `IdleState`.
  * *Comportamento no Greybox:* Micro-ciclo de respiração sutil (oscilação suave de 2px no tronco) e ondulação da faixa na cabeça.
  * *Regra de Ouro:* Cancelamento instantâneo no frame 0 por qualquer input, garantindo resposta imediata sem travar o jogador.
