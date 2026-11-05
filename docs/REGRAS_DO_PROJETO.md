# Regras do Projeto — Severed Dawn

> [!IMPORTANT]
> ## LEITURA OBRIGATÓRIA ANTES DE QUALQUER AÇÃO
> Todo agente ou desenvolvedor que for atuar neste repositório **DEVE OBRIGATORIAMENTE LER PRIMEIRO**:
> 1. [`docs/BRAINSTORMING.md`](BRAINSTORMING.md) — Contém todos os 3 Pilares oficiais do jogo: Lore/História, Metaprogressão da Casa Santuário, Sistema de Combate dos 3 Sinais, Física de Movimentação, Métricas de Saltos e Geração em 3 Camadas de Biomas.
> 2. Este arquivo [`docs/REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md).
> 
> **Não inicie nenhuma tarefa sem carregar estes documentos no contexto.**

---

## 1. Governança e Regras de Operação com o PO

### Regra 1: Push sob Demanda Estrita (A Mais Crítica)
* **NUNCA** fazer push para o repositório remoto por conta própria ou de forma automática.
* Fazer push **EXATAMENTE UMA VEZ** apenas quando o PO solicitar explicitamente (*"faça o push"*, *"pode subir"*, *"push e prossiga"*).
* Após realizar o push solicitado, **aguardar o próximo pedido explícito** para qualquer novo push.
* Todos os commits intermediários são estritamente **locais** (`git commit`).

### Regra 2: Centralização de Documentos na Pasta `docs/`
* **TODOS os documentos** de design, planos, especificações, arquitetura e notas técnicas devem ser criados e mantidos **obrigatoriamente dentro da pasta `docs/`**.
* O único arquivo markdown permitido na raiz do repositório é o [`README.md`](../README.md).

### Regra 3: Modo de Operação Tech Leader & Granularidade Estrita
* A IA atua como **Tech Leader**: postura técnica, crítica, analítica e sem enrolação ou bajulação.
* Trabalhar estritamente **ponto a ponto, um de cada vez**. Nunca atropelar decisões nem apresentar múltiplos blocos de escolhas sem validação prévia.
* Antes de apresentar qualquer ponto ou subponto técnico ao PO, **pesquisar obrigatoriamente na internet como os jogos de referência da indústria resolvem aquele desafio** e apresentar o comparativo de mercado.

### Regra 4: Parada Obrigatória para Validação do PO
* Ao final de cada fase, funcionalidade, script ou cena, a IA deve **obrigatoriamente parar** e apresentar um resumo claro do que foi feito e como o PO deve testar.
* Nenhum avanço para o próximo passo pode ser feito sem a aprovação explícita do PO.

---

## 2. Seleção Obrigatória de Skills Antes de Qualquer Ação

### Regra 5: Triagem Prévia de Skills por Tarefa
* **SEMPRE** que o agente for iniciar uma nova tarefa (editar arquivos, explorar código, pesquisar, gerar arte/sprites, criar cenas ou depurar), ele deve **listar mentalmente ou em texto as skills disponíveis** no projeto e no sistema, selecionando explicitamente a(s) melhor(es) para orientar a execução:
  * **`.agents/skills/godot-programming`**: Para padrões de nós na Godot 4, FSM em GDScript 2.0, tipagem forte e Custom Resources (`.tres`).
  * **`.agents/skills/gamedesign-roguelike`**: Para regras de ouro de *feel* (coyote time, jump buffer, hitstop, i-frames, combate dos 3 sinais).
  * **`.agents/skills/platformer-spritesheet-gen`**: Para geração, alinhamento de grid e sincronização de animações 2D de plataforma.
  * **`.agents/skills/platformer-leveldesign`**: Para métricas espaciais (relação de pulo com grade de tiles, clearance de teto).
  * **`.agents/skills/procedural-level-design`**: Para o algoritmo de grafos, macro-padrões e conexão de chunks.
  * **`.agents/skills/gaming-ui-ux`**: Para HUD diegética, barra de bosses e acessibilidade a gamepads.
  * **`.agents/skills/game-audio-juice`**: Para vibração tátil no gamepad, shaders de hit-flash e efeitos de impacto.
  * **`.agents/skills/godot-debugging`**: Para validação headless CLI (`godot --headless --check-only`), detecção de memory leaks e testes.

---

## 3. Preservação Rígida da Identidade Visual

### Regra 6: Coerência Visual Inegociável & Direção de Arte (Zero Bagunça)
Todos os assets visuais (protagonista, inimigos, armas, cenários e NPCs) devem parecer pertencer rigorosamente ao **MESMO jogo e universo visual**:
* **Proibição de Disparidade de Estilo:** É expressamente proibido misturar assets realistas com estilos cartoon/chibi, ou assets ultra-detalhados com pixel art simplório, a menos que o PO especifique explicitamente.
* **Proibição de "Mixels" (Densidade de Pixels Idêntica):** Todos os sprites do jogo compartilham a mesma escala nativa de pixels na tela (1 pixel no asset = 1 pixel na resolução 640 × 360). Nenhum asset pode parecer ter pixels menores ou maiores que os outros.
* **Linguagem Visual e Sombreamento Padronizados:**
  * Personagens e monstros compartilham a mesma gramática de contorno (outlines escuros) e sombreamento (paleta contida com 2 a 3 tons de sombra por material).
  * Universo estético: **Dark Fantasy Rústico e Sombrio** (tons terrosos, ferro forjado, pedra úmida, sangue denso e o brilho espectral arroxeado/ciano da Morte).
* **Escala de Resolução Estrita:** Resolução interna travada em **640 × 360 px** (proporção 16:9 pixel-perfect).
* **Grade de Tiles Base:** Padrão **16 × 16 pixels**. Qualquer bloco composto deve ser múltiplo exato (32×32, 64×64).
* **Proporção do Personagem:** Rigorosamente **16 pixels de largura × 40 pixels de altura**.
* **Pivô nos Pés (Feet-Pivot):** Todo sprite de personagem e inimigo deve ter seu ponto de ancoragem/origem exatamente no **centro-inferior (entre os pés)**, garantindo que transições de animação nunca façam o corpo afundar ou tremer no chão.
* **Efeitos Compatíveis:** Efeitos mágicos e de fogo utilizam `GPUParticles2D` + Shaders 2D e iluminação dinâmica com `PointLight2D` integrados à paleta do jogo.

---

## 4. Engenharia, Validação e Autonomia

### Regra 7: Autonomia de Processo e Ferramental
* O agente tem acesso total ao terminal Windows e ao executável da Godot (`C:\tools\godot\godot.exe`).
* **PROIBIDO pedir para o usuário fechar janelas ou copiar/colar logs de erro.** O agente inspeciona logs, processos e saídas de terminal proativamente.

### Regra 8: Validação Limpa Obrigatória (Headless CLI)
* Antes de entregar qualquer código ou cena para o PO testar, o agente deve rodar a checagem headless da Godot via terminal:
  ```powershell
  godot --headless --check-only --path .
  ```
* Nenhuma cena com dependência quebrada, script com erro de sintaxe ou referência nula pode ser passada para teste do PO.
