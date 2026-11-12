# Guia Técnico de Implementação de Sprites, Sockets de Armas e Slashes (Pixel Marker Pipeline)

> **INSTRUÇÃO PARA O AGENTE DE IA:**  
> Antes de executar qualquer tarefa relacionada a sprites do Player, animações, calibração de sockets de armas/escudos ou efeitos de ataque (slash), você **DEVE obrigatoriamente** ler os documentos listados na seção **1. Leituras Obrigatórias** abaixo e seguir rigorosamente este protocolo técnico.

---

## 1. Leituras Obrigatórias do Projeto

Antes de iniciar qualquer implementação, leia na íntegra:
1. **[`README.md`](../README.md)** — Visão geral da arquitetura, estrutura de pastas, controles e mecânicas implementadas.
2. **[`docs/REGRAS_DO_PROJETO.md`](./REGRAS_DO_PROJETO.md)** — Regras absolutas de engenharia, testes headless e fluxo de trabalho.
3. **[`.agents/rules/git-workflow.md`](../.agents/rules/git-workflow.md)** — Regras de versionamento (**NUNCA faça `git push` sem comando explícito do usuário**).
4. **[`.agents/rules/po-workflow.md`](../.agents/rules/po-workflow.md)** — Postura de Tech Leader, objetividade e autonomia técnica.
5. **Arquivos-chave do Sistema de Sockets e Combate:**
   - [`src/entities/equipment/socket_profiles/weapon_socket_profile.gd`](../src/entities/equipment/socket_profiles/weapon_socket_profile.gd)
   - [`src/tools/weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd)
   - [`src/entities/player/player.gd`](../src/entities/player/player.gd)
   - [`src/combat/weapon_data.gd`](../src/combat/weapon_data.gd)

---

## 2. Visão Geral do Pipeline de Marcação por Pixels (Color Markers)

O usuário (PO) fornece spritesheets (ou frames) contendo **pixels guia coloridos** desenhados diretamente na arte para indicar onde as armas da mão principal, armas/escudos das costas e âncoras de efeito (slash) devem ser posicionados matematicamente.

### O Fluxo de Trabalho do Agente consiste em 5 Etapas:
1. **Análise via Script (Python/PIL):** Ler a imagem enviada pelo usuário, detectar as coordenadas `(x, y)` e o ângulo (`atan2`) dos pixels marcadores em cada célula (frame) do grid.
2. **Limpeza do Sprite Final:** Remover TODOS os pixels marcadores (verde, rosa/roxo, amarelo) restaurando a transparência (`RGBA(0, 0, 0, 0)`) ou cor original antes de salvar a versão final do spritesheet e os frames individuais na pasta `assets/`.
3. **Cálculo Matemático dos Sockets:** Converter as coordenadas locais do pixel dentro da célula `(cell_x, cell_y)` para o espaço de coordenadas do nó `$Visual` do Player no Godot e calcular a rotação exata em graus para cada arma.
4. **Gravação nos Recursos `.tres`:** Salvar os dados calculados nos perfis de socket em `src/entities/equipment/socket_profiles/*.tres` (`sword.tres`, `hammer.tres`, `axe.tres`, `dagger.tres`, `shield.tres`, `bow.tres`, `crossbow.tres`, `staff.tres`).
5. **Validação Headless:** Importar as texturas e validar com o Godot via terminal (`--headless --check-only`).

---

## 3. Código de Cores dos Marcadores nos Sprites

Quando o usuário enviar uma imagem de animação (ex: `attack1`, `attack2`, `attack3`, etc.), procure pelos seguintes marcadores de cor:

### A. Linha VERDE (`R < 100, G > 200, B < 100`) — Mão Principal (`MainHandSocket`)
- **O que representa:** O vetor da arma empunhada na mão principal (da empunhadura/cabo até a ponta da lâmina).
- **Ponto Inicial (Empunhadura / Mão):** O pixel verde **mais próximo da mão/corpo do personagem**. É aqui que o socket da mão (`pos`) será posicionado.
- **Ponto Final (Ponta da Lâmina):** O pixel verde **mais distante do corpo** na extremidade da linha.
- **Ângulo da Linha ($\theta$):** Calculado do ponto da mão `(x0, y0)` até a ponta `(x1, y1)`:
  $$\text{angle\_deg} = \text{degrees}(\text{atan2}(y_1 - y_0, x_1 - x_0))$$
- **Armas que usam a linha verde na mão:**
  - **`sword` (Espada):** Segue exatamente a posição da mão e o ângulo $\theta$ da linha verde (em `sword_visual.tscn`, a lâmina aponta para `+X`, `0°`).
  - **`hammer` (Martelo):** Segue a mesma posição e ângulo $\theta$ da espada (cabeça do martelo aponta para `+X`, `0°`).
  - **`axe` (Machado):** Segue a mesma posição e ângulo $\theta$ da espada.
    - **Atenção ao Flip do Machado (`flip_v`):** Em `axe_visual.tscn`, a lâmina cortante é desenhada para o lado `-Y` (para cima quando em `0°`). Se durante o arco do ataque a lâmina ficar virada para o lado contrário do movimento do corte, ative `"flip_v": true` naquele frame específico dentro de `hand_frames[key]`!
  - **`dagger` (Adaga):** O usuário costuma calibrar a adaga manualmente no calibrador visual (verifique se ele pediu para pular ou incluir a adaga).
  - **`bow`, `crossbow` e `staff`:** **NÃO** são posicionados na mão principal em animações de ataque melee (`attack1`, `attack2`, `attack3`), pois possuem padrões de disparo/ataque mágicos próprios. Entram **exclusivamente nas costas (`back_frames`)** como arma secundária guardada!

---

### B. Linha ROSA / MAGENTA (`R > 200, G < 80, B > 180`) — Costas (`BackSocketWeapon` e `BackSocketShield`)
- **O que representa:** A linha das costas/ombro do personagem, indicando a inclinação do torso.
- **Ponto de Referência (`P_top`):** O pixel rosa **mais alto** (menor `Y`). A direção da linha desce do ponto mais alto `(x_top, y_top)` para o ponto mais baixo `(x_bot, y_bot)` ao longo das costas.
- **Ângulo das Costas ($\theta_{\text{back}}$):**
  $$\theta_{\text{back}} = \text{degrees}(\text{atan2}(y_{\text{bot}} - y_{\text{top}}, x_{\text{bot}} - x_{\text{top}}))$$
- **Como posicionar cada equipamento nas costas (`back_frames`):**
  - **Z-Index nas costas:** Sempre `z_index = -2` para armas e `z_index = -1` para escudo (para ficarem escondidos atrás do corpo/capa do personagem).
  - **`shield` (Escudo):** O topo do escudo começa no ponto rosa mais alto e desce escondido atrás das costas. Posicione o centro do escudo deslocado alguns pixels ao longo do vetor das costas a partir do ponto rosa mais alto, acompanhando a inclinação $\theta_{\text{back}}$.
  - **`sword` (Espada nas costas):** O pomo (cabo) fica para cima começando no primeiro ponto rosa (mais alto) e a lâmina desce ao longo das costas na direção $\theta_{\text{back}}$. Como o cabo da espada fica em `-X` (`-6px`) da origem do `SwordVisual`, desloque a origem alguns pixels na direção de $\theta_{\text{back}}$ para que o pomo coincida exatamente com o ponto rosa mais alto.
  - **`hammer` (Martelo nas costas):** A cabeça do martelo começa no ponto rosa mais alto e o cabo desce ao longo das costas. Como a cabeça do martelo fica em `+X` (`+16px`) da origem do `HammerVisual`, aponte a rotação para $\theta_{\text{back}} - 180^\circ$ e posicione a origem mais abaixo nas costas para que a cabeça fique no topo rosa.
  - **`axe` (Machado nas costas):** A ponta de cima do machado começa no ponto rosa mais alto e o cabo desce, com a **lâmina (parte do corte) virada na direção contrária para onde o personagem está olhando** (para trás/esquerda). Ajuste `rot` para $\theta_{\text{back}} - 180^\circ$ e use `flip_v` conforme necessário para garantir que a lâmina aponte para a esquerda (`-X`).
  - **`bow` (Arco nas costas):** O grip (empunhadura central) do arco fica posicionado ao longo da linha rosa das costas (`z_index = -2`). Como a corda é desenhada em $X=0$ e os membros do arco curvam para $+X$, a rotação deve acompanhar a inclinação das costas (geralmente entre $-170^\circ$ e $-190^\circ$, ou $\theta_{\text{back}} - 270^\circ$) para que o arco repouse rente ao dorso do personagem.
  - **`staff` (Cajado nas costas):** A ponta/cristal superior do cajado começa no primeiro ponto rosa (`P_top`) e a haste desce ao longo da linha magenta das costas (`z_index = -2`), acompanhando o ângulo $\theta_{\text{back}}$.
  - **`crossbow` (Besta nas costas / cintura):** A besta fica guardada no coldre lateral/cintura nas costas (`back_frames`, `z_index = -2`). Posicione a coronha na esquerda sobre a linha amarela da cintura, apontando a ponta da flecha para a frente na horizontal (`rot` entre $0^\circ$ e $10^\circ$), conforme detalhado na Seção C abaixo.

---

### C. Linha AMARELA na Cintura (`R > 200, G > 200, B < 50`) — Besta na Cintura (`crossbow` em `back_frames`)
- **O que representa:** Pixels amarelos na altura da cintura do personagem indicam onde a **Crossbow (Besta)** fica guardada quando está no slot secundário (`back_frames`).
- **Posição e Orientação:** A besta fica na **horizontal** na cintura: a coronha/cabo começa na esquerda e a frente (onde fica a ponta da flecha) aponta para a direita (frente do personagem), exatamente sobre os pixels amarelos (`rot` próximo de `0°` a `10°`, e `z_index = -2` ou conforme calibrado).

---

### D. Pixel AMARELO Único no Pé / Grid de Efeito — Âncora de Alinhamento 1:1 (Slash Effects)
- Quando o usuário envia um sprite de **efeito de corte (Slash)** separado do personagem, ele marca **1 pixel amarelo** na posição correspondente à **sola do pé esquerdo do aventureiro** (ex: coordenada `(25, 59)` em um frame de `83x62`).
- **Como funciona:**
  - No Godot, a origem `(0, 0)` do `Player` fica exatamente nos pés.
  - O `PlayerSprite` (`83x62`) e o `SlashEffect` (`AnimatedSprite2D`, `83x62`) usam a mesma posição base `Vector2(-2, -29)`.
  - Ao recortar os frames do slash com o mesmo tamanho de célula (`83x62`) mantendo o pixel amarelo na mesma coordenada relativa `(25, 59)` (e apagando o pixel amarelo na imagem final), o corte fica **100% pixel-perfect alinhado** na frente do personagem!

---

## 4. Matemática de Conversão de Coordenadas (Sprite $\rightarrow$ Godot)

No Godot (`src/entities/player/player.tscn` e `player.gd`):
- O nó `PlayerSprite` (`AnimatedSprite2D`) está posicionado em `Vector2(-2, -29)` relativo ao nó `$Visual` (cuja origem `(0, 0)` é o pé do personagem no chão).
- Como o `AnimatedSprite2D` tem `centered = true` por padrão, o canto superior esquerdo `(0, 0)` de um frame de largura $W$ e altura $H$ fica em:
  $$\text{top\_left} = \text{Vector2}(-2, -29) - \text{Vector2}\left(\frac{W}{2}, \frac{H}{2}\right)$$
- **Exemplo para frames de `83x62` pixels (usados em `attack1`, `attack2`, `attack3`):**
  $$\text{top\_left} = \text{Vector2}(-2 - 41.5, -29 - 31.0) = \text{Vector2}(-43.5, -60.0)$$
- Portanto, qualquer pixel na coordenada `(px, py)` dentro da célula de `83x62` converte para a posição do Socket no Godot pela fórmula:
  $$\text{socket\_pos.x} = \text{ round}(px - 43.5)$$
  $$\text{socket\_pos.y} = \text{ round}(py - 60.0)$$

> **Sempre verifique o tamanho da célula $(W, H)$ do spritesheet enviado!** Se o frame for `50x37` (como em `idle`/`run`), $\text{top\_left} = (-2 - 25, -29 - 18.5) = (-27.0, -47.5)$.

---

## 5. Como Salvar nos Perfis de Socket (`WeaponSocketProfile`)

Os perfis de socket ficam em `src/entities/equipment/socket_profiles/*.tres` e usam o script [`weapon_socket_profile.gd`](../src/entities/equipment/socket_profiles/weapon_socket_profile.gd).

1. **Animações com propriedades exportadas diretas** (`idle`, `run`, `jump`, `crouch`, `fall`, `fall_from_jump`, `slide`, `roll`, `double_jump`, `wall_cling`, `wall_slide`, `corner_climb`):
   - Posição e rotação da mão ficam em propriedades diretas como `idle_0_pos`, `idle_0_rot`, `idle_0_visible`, E também sincronizadas no dicionário `hand_frames["idle_0"]`.
2. **Animações de combate e extras** (`attack1`, `attack2`, `attack3`, `air_attack`, `cast`, `guard`, `stagger`, `die`):
   - Os dados da mão principal ficam armazenados no dicionário exportado **`hand_frames`** usando a chave `"<anim>_<frame>"` (ex: `"attack1_0"`, `"attack1_1"`, ..., `"attack1_4"`):
     ```gdscript
     hand_frames["attack1_0"] = {
         "pos": Vector2(-7, -25),
         "rot": -205.0,
         "visible": true,
         "z_index": 2,
         "flip_h": false,
         "flip_v": false
     }
     ```
   - Os dados das costas ficam armazenados no dicionário exportado **`back_frames`** com a mesma chave `"<anim>_<frame>"`:
     ```gdscript
     back_frames["attack1_0"] = {
         "pos": Vector2(-11, -35),
         "rot": -42.0,
         "visible": true,
         "z_index": -2,
         "flip_h": false,
         "flip_v": false
     }
     ```
3. **Importante sobre o Calibrador Visual (`weapon_socket_calibrator.gd`):**
   - Sempre que adicionar uma nova animação ou alterar a quantidade de frames de uma animação em `assets/player/adventurer/player_frames.tres`, atualize a constante `ANIMATION_FRAME_COUNTS` em [`src/tools/weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd) para que o calibrador saiba exatamente quantos frames aquela animação possui.
   - O flip (`flip_h` e `flip_v`) no calibrador funciona **individualmente por frame** (protegido pela flag `_is_syncing_from_frame`). Nunca altere isso para comportamento global.

---

## 6. Checklist Passo a Passo para Quando o Usuário Enviar um Novo Sprite

Quando o usuário enviar um novo sprite (ex: o novo `attack2` ou `attack3` com marcações verde, rosa e amarela):

1. **Inspecione a Imagem com Python:**
   - Verifique as dimensões totais e o grid de células (ex: `83x62` por frame).
   - Extraia as coordenadas dos pixels verdes (mão), rosas (costas) e amarelos (cintura/âncora) de cada frame.
   - Se o usuário pedir apenas confirmação visual antes de prosseguir, liste os frames encontrados e confirme que leu os marcadores.
2. **Gere os Arquivos de Imagem Limpos:**
   - Apague todos os pixels marcadores (verdes, rosas e amarelos) substituindo por transparente `(0, 0, 0, 0)` (ou pela cor adjacente do corpo se estiver sobreposto).
   - Se houver rastro de slash desenhado no sprite e o usuário quiser separado, separe o slash para `assets/effects/slashes/` e deixe o corpo do personagem limpo em `assets/player/adventurer/attack/`.
   - Salve a spritesheet limpa (ex: `player_attack2_sheet.png`) e os frames individuais (`individual/adventurer_attack2_00..04.png`).
3. **Atualize os Sockets (`.tres`):**
   - Calcule `pos`, `rot`, `z_index`, `flip_h` e `flip_v` para `hand_frames` (`sword`, `hammer`, `axe`, `staff`) e `back_frames` (`shield`, `sword`, `hammer`, `axe`, `bow`, `crossbow`, `staff`) e grave nos arquivos `.tres` via script GDScript headless ou edição direta.
4. **Valide no Godot Headless:**
   - Execute a importação e validação de sintaxe:
     ```powershell
     godot --headless --check-only --path .
     ```
   - Certifique-se de que há **0 erros**.
5. **Commit Local (Sem Push!):**
   - Faça `git add` e `git commit` local descrevendo a calibração.
   - **Aguarde o usuário testar no editor e ordenar explicitamente `"faça push"` antes de enviar ao repositório remoto.**
