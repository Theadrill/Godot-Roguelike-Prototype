# Severed Dawn - Game Design Document (Protótipo)

Documento vivo de concepção e especificações técnicas do protótipo **Severed Dawn**, um Roguevania 2D focado em combate visceral, fluidez de movimentação e impacto (estilo Dead Cells).

---

## 🏛️ Pilar 1: Identidade, Nome e Premissa da História
> *Status: OFICIALIZADO*

* **Título Oficial**: **Severed Dawn** (Alvorecer Rompido)
* **Verificação de Copyright**: 100% verificado e livre em lojas de jogos (Steam/Itch/Consoles), livros (Amazon/Goodreads), filmes (IMDb) e marcas registradas (USPTO).

### 1. Resumo da Premissa
Você é um rapaz comum, sem treino militar, vivendo com sua mãe (uma renomada curandeira) e seu irmão mais novo (um promissor criador de equipamentos) nos arredores de um vilarejo pacífico. No dia fatídico, o exército de um General tirânico invade a região em busca de uma relíquia divina. Você assiste impotente à execução brutal de sua mãe e de seu irmão antes de ser morto logo em seguida.

No além, você é recebido pelo próprio **Deus da Morte**. A divindade revela que o General roubou um fragmento vital do domínio da Morte. Enfraquecido e incapaz de agir diretamente no plano mortal, o Deus da Morte faz um pacto com você: ser seu **Avatar** mortal em troca de recuperar o que foi roubado, sob a bênção/maldição de **reviver aquele mesmo dia indefinidamente**.

Ao acordar de volta na cama, sua família está viva e salva dentro de casa. **A porta da frente é o limiar**: no segundo em que você gira a maçaneta e pisa para fora, o dia do massacre recomeça, a invasão explode e sua missão tem início.

### 2. A Casa da Família (O Santuário Limiar & Metaprogressão)
* **A Lore do Refúgio Temporal:** A casa está protegida do fluxo do espaço/tempo como parte da barganha com a Morte. O interior da casa retém memórias, conhecimentos e construções. Novos sobreviventes e NPCs resgatados nas runs encontram refúgio na casa, expandindo os serviços disponíveis.
* **O Irmão (O Aspirante a Forjador):**
  * Sendo um aprendiz, cria armas base rústicas e improvisadas.
  * Inimigos e chefes dropam **Projetos de Equipamentos (Blueprints)**. Ao entregá-los ao irmão, ele aprende a forjar novas categorias de armas permanentemente.
* **A Mãe (A Curandeira):**
  * Precisa de ervas medicinais e extratos de monstros coletados nas fases para preparar frascos com mais cargas, curas instantâneas, antídotos e elixires de bônus pré-run.
* **O Toque da Morte (Encantamento & Ascensão):**
  * As armas rústicas do irmão ganham vida pelo poder da Morte. O investimento de essências/almas desbloqueia graus mais altos de encantamentos: dano necrótico, sangramento, velocidade e habilidades ativas.

---

## ⚔️ Pilar 2: Gameplay, Mecânicas de Combate & Game Feel
> *Status: OFICIALIZADO*

### 1. Física e Movimentação (Determinística e Ágil)
* **Controle Horizontal Instantâneo**: Aceleração rápida (~0.08s) e parada seca sem inércia escorregadia.
* **Pulo Fixo + Pulo Duplo**:
  * Pulo sem altura analógica: apertou, atinge a altura total imediatamente.
  * *1º Pulo:* 4 tiles de altura (64 px).
  * *Pulo Duplo:* +3 tiles de altura (+48 px) $\rightarrow$ total de 7 tiles (112 px).
  * Gravidade de descida acelerada (~1.3x) para queda firme e ágil.
* **As Regras de Ouro do "Feel":**
  * *Coyote Time:* 0.12s de tolerância para pular após sair de uma plataforma.
  * *Jump Buffer:* 0.12s de antecipação para disparar o salto no primeiro frame de aterrissagem.
* **Pulo na Parede (Wall-Jump):**
  * Suporte a *Wall-Slide* e *Wall-Jump* com vetor diagonal de repulsão e trava de input de 0.1s para arco limpo de saída.
* **Rolamento com Invulnerabilidade Total (Dodge Roll):**
  * Arrancada horizontal com i-frames durante toda a janela ativa.
  * Atravessa corpos de inimigos e cancela animações de ataque básico.
* **Estados Preparados (Stubs):**
  * *Idle Breaks:* Variações de animação após 5s de inatividade com cancelamento instantâneo por qualquer input.
  * *Ground Slam:* Mapeamento de Baixo + Pulo no ar para esmagamento descendente.

### 2. O Sistema Tático de Combate (Os 3 Sinais)
* **Sem Hyper-Armor em Mobs Comuns:** Se o jogador atacar primeiro, o golpe cancela o ataque do inimigo no primeiro frame e o coloca em *stunlock*.
* **Knockback Atrelado à Arma (WeaponData):**
  * Adagas: Knockback zero (mantém o inimigo colado para DPS).
  * Espadas: Knockback moderado no finalizador.
  * Armas pesadas: Knockback e quebra de ataque massivos.
* **O Sistema de 3 Sinais Visuais de Ataque:**
  * *Sem Sinal (Normal):* Interrompível pelo corte do jogador.
  * *Amarelo (Pesado):* Ininterruptível. Resposta em 3 níveis (Parry Perfeito = 100% defesa e atordoamento; Bloqueio Simples = 15% chip damage; Bloqueio Tardio = penalidade).
  * *Vermelho (Perilous):* Proibido segurar escudo (quebra de guarda e 100% de dano). Exige **Parry Perfeito** ou **Rolamento com i-frames**.
* **Feedback Visual e Tátil Limpo (Diegético):**
  * Sem números flutuantes de dano e sem barras em cima de monstros comuns.
  * Reação física: flash via shader no inimigo + 1 animação universal de dano (*hurt*) + jatos de sangue direcionais no ângulo do corte.
  * Vibração no Gamepad via motor duplo da Godot 4 em vez de screen shake.
  * Barra de vida maciça apenas para Chefes no centro inferior da tela.

---

## 🗺️ Pilar 3: Level Design, Grade de Tiles e Estrutura das Fases
> *Status: OFICIALIZADO*

### 1. Resolução e Métricas Espaciais
* **Resolução Base:** **640 × 360 pixels** (proporção 16:9 pixel-perfect com escala inteira para 1080p, 1440p e 4K).
* **Grade de Tiles:** **16 × 16 pixels** (flexível, permitindo plataformas finas de 16px e blocos compostos de 32px ou 64px).
* **Dimensões do Personagem:** **16 px de largura × 40 px de altura** (passa em corredores de 48px; exige rolamento em vãos de 32px).
* **Régua de Saltos:**
  * 1º Pulo: 4 tiles de altura (64 px) | Vão horizontal: 4 tiles (64 px).
  * Pulo Duplo: 7 tiles de altura acumulada (112 px) | Vão horizontal: 6 tiles (96 px).

### 2. Estrutura Modular dos Chunks & Câmera
* **Módulo Base do Chunk:** **40 × 22 tiles** (640 × 352 px = 1 tela inteira).
* **Salas Multi-Chunk (Flexibilidade):**
  * Chunks $1 \times 1$: Arenas e salas secretas.
  * Chunks $2 \times 1$ ou $3 \times 1$: Ruas longas e pontes contínuas.
  * Chunks $1 \times 2$: Poços verticais para wall-jump.
* **Câmera:** Contínua e suave (`Camera2D` com lerp), com *look-ahead* dinâmico e *deadzone* central para evitar motion sickness. Sem cortes de tela.

### 3. A Hierarquia em 3 Camadas de Geração Procedural (Padrão Dead Cells)
* **Camada 1: O Bioma (Tema do Mundo):**
  * *Bioma 1:* Arredores do Vilarejo em Chamas.
  * *Bioma 2:* Esgotos da Cidadela.
  * *Bioma 3:* Muralhas e Pátio da Fortaleza.
  * *Bioma 4:* Salão do Trono do General.
* **Camada 2: Padrões Estruturais (Macro-Grafos):**
  * Cada bioma tem arquétipos sorteados (ex: *Padrão Linear*, *Padrão Labiríntico com Telhados*, *Padrão Bifurcado*).
  * O padrão estabelece o **Caminho Crítico** (da Casa à Saída) e **Ramos Secundários** (Dead Ends para Projetos do Irmão e Ingredientes da Mãe).
* **Camada 3: Os Chunks:**
  * O algoritmo preenche o padrão estrutural sorteando chunks artesanais específicos daquele bioma interligados via marcadores de porta (`Marker2D`).
