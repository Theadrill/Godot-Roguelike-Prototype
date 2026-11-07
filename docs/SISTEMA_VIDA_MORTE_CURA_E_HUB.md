# 🩸 Arquitetura do Loop de Vida, Morte, Cura e o Hub Familiar

> [!IMPORTANT]
> ## 🚨 LEITURA OBRIGATÓRIA ANTES DE QUALQUER AÇÃO
> Todo agente ou desenvolvedor que for atuar nesta funcionalidade **DEVE OBRIGATORIAMENTE LER PRIMEIRO**:
> 1. [`docs/REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md) — As regras inegociáveis de governança, push sob demanda, granularidade e parada para sprites.
> 2. **Tudo o que estiver referenciado nele:**
>    * [`docs/BRAINSTORMING.md`](BRAINSTORMING.md) — Os 3 Pilares fundamentais de gameplay, Lore, Santuário da Família, 3 Sinais de Combate e Métricas Espaciais.
>    * [`docs/ARQUITETURA_PROGRESSAO_INIMIGOS_E_TIERS.md`](ARQUITETURA_PROGRESSAO_INIMIGOS_E_TIERS.md) — Sistema de Níveis, Tiers em cascata (1/2/3) e IA de cooldown adaptativa.
>    * [`docs/PLANO_DE_IMPLEMENTACAO_INICIO_DO_PROJETO.md`](PLANO_DE_IMPLEMENTACAO_INICIO_DO_PROJETO.md) — Histórico de fases de implementação do projeto.
>
> ---
>
> ## 🛑 REGRA DE EXECUÇÃO: ALINHAMENTO PRÉVIO A CADA PASSO
> **A cada um dos passos descritos neste documento:**
> 1. O desenvolvedor/agente deve **apresentar o resumo claro do que será feito naquele passo específico**.
> 2. Deve **perguntar formalmente ao PO**: *"Deseja alinhar ou ajustar mais algum detalhe antes de implementarmos este passo?"*.
> 3. **NENHUMA linha de código ou cena poderá ser criada/modificada antes da confirmação explícita do PO.**
> 4. Após implementar e testar, deve apresentar o resumo do resultado e como testar antes de sequer propor o próximo passo.

---

> **Status:** OFICIALIZADO E APROVADO  
> **Data:** Novembro de 2026  
> **Projeto:** Severed Dawn (Godot 4.7 Roguevania Prototype)  
> **Pilares Envolvidos:** Pilar 2 (Combate & Risco) e Pilar 4 (Meta-Progressão & Narrativa da Família)

---

## 1. Visão Geral & Filosofia de Design

O ciclo de vida e morte de *Severed Dawn* rejeita o niilismo genérico dos roguelikes convencionais. A morte do protagonista não é apenas um "game over mecânico", mas uma **anomalia temporal cíclica** que o devolve ao único refúgio seguro do vale: **A Casa da Família**.

* **O Contraste Emocional (Ghibli vs Dark Souls):** O interior da casa é caloroso, vívido e acolhedor (a Mãe cozinhando, o Irmão na forja, os pets dormindo no chão). Ao cruzar o limiar da porta envolta na névoa da Morte, o guerreiro entra no mundo exterior em ruínas e chamas.
* **A Justificativa da Geração Procedural:** Cada colapso temporal desfaz e reconfigura o tecido geográfico da terra. Por isso, **não existe mancha de sangue ou sombra a ser recuperada**: o local da morte anterior foi reescrito pela anomalia temporal.

---

## 2. A Mecânica da Garrafa de Chá da Mãe (Health Flask)

O item de cura do protagonista é a **Garrafa de Chá da Mãe** — preparada com carinho na cozinha da Casa Santuário antes de cada incursão pelo vale. O frasco opera em valores percentuais para garantir relevância matemática em qualquer estágio de progressão da vida do guerreiro:

1. **Parâmetros Base da Run:**
   * **Quantidade Inicial:** `1 carga` por padrão.
   * **Potência Base:** Recupera instantaneamente **40% da Vida Máxima** do jogador.
   * **Canalização / Risco:** O jogador planta os pés no chão por **`0.55s`** (telegraph diegético de brilho esmeralda no peito). Se for atingido por golpe inimigo durante a canalização, a cura é interrompida.
   * **Preservação de Carga no Dano (Padrão Nine Sols):** Se interrompido por dano inimigo antes dos 0.55s, o jogador toma dano e a cura falha, mas **a carga não é desperdiçada**. A carga só é debitada ao concluir com sucesso a canalização.
   * **Comando Padrão:** Botão dedicado (`Q` no Teclado / `D-Pad Cima` no Gamepad).

2. **Tentativa de Cura Sem Cargas (Barks Diegéticos Aleatórios):**
   * Ao tentar beber com 0 cargas disponíveis, o herói não inicia a animação de canalização; em vez disso, emite um **aviso diegético sutil (Bark)** acima da cabeça sorteado aleatoriamente de um pool textual:
     * *"Putz, acabou o chá!"*
     * *"Acabou o chá..."*
     * *"Devia ter trazido mais chá"*
     * *"Já acabou o chá?..."*
   * As frases nunca são hardcoded em código: residem no catálogo/banco de localização do jogo (`res://src/core/localization/translations.csv`) e são puxadas dinamicamente via chave de tradução.

3. **Pré-requisito Arquitetural: Passo 0 — Fundação de Localização (i18n):**
   * Antes de codificar a mecânica do frasco, é obrigatória a implantação da fundação de linguagem do projeto descrita em [`docs/REFERENCIA_DO_SISTEMA_DE_LINGUAGEM.md`](REFERENCIA_DO_SISTEMA_DE_LINGUAGEM.md).
   * Todo sistema novo já nasce consumindo chaves oficiais e suportando internacionalização (inicialmente `pt_BR`, estruturado nativamente para expansão imediata a outros idiomas).

4. **Progressão Permanente com a Mãe:**
   * Entregando ervas e ingredientes raros na cozinha da Casa, a Mãe aprimora a garrafa para **2, 3 e até 4 cargas**, além de expandir a eficácia (45%, 50%, etc.).

5. **Ganchos de Modificadores (Afixos Especiais):**
   * Mecânicas como *recarregar frações de frasco ao acertar Parries Perfeitos ou executar inimigos* funcionam como **modificadores/amuletos/bênçãos**, e não como habilidade inata básica.
---

## 3. O Rali Tático de Vida (Parry-Driven Rally)

Diferente de sistemas que incentivam esmagar botões de ataque em pânico para recuperar vida perdida:

* **Janela de Retaliação:** Ao receber dano, uma porção da vida perdida permanece como um rastro cinza/alaranjado por **`2.0 segundos`**.
* **Condição de Recuperação:** Golpes normais **NÃO** recuperam essa vida.
* **A Recompensa da Maestria:** O guerreiro precisa manter a compostura e desferir um **Parry Perfeito** contra o próximo ataque inimigo. O contra-ataque resultante (*riposte*) estilhaça o rastro e regenera a vida do golpe anterior.

---

## 4. A Morte do Protagonista & Penalidades da Run

Ao atingir `0` de HP:

1. **Efeito Audiovisual Diegético:**
   * Slow-motion dramático (`Engine.time_scale = 0.2` por `0.8s`).
   * Escurecimento gradual da tela (*fade to black*).
   * Mensagem sóbria diegética (*"O Sangue Cessa"* / *"Severed"*).
   * Som de distorção temporal reiniciando o dia.

2. **Perdas na Morte:**
   * **Nível da Run:** Reseta para o **Nível 1**.
   * **Armas Empunhadas:** Perdidas; o guerreiro renasce com o equipamento inicial escolhido no baú da Casa.
   * **Inventário da Run:** Todas as Receitas e Ingredientes que estavam na sacola e não foram descarregados no Baú Transtemporal se perdem na anomalia temporal.

3. **O Baú Transtemporal (Salas de Transição entre Biomas):**
   * Localizado no refúgio seguro entre um bioma e outro.
   * **O que aceita:** Receitas/Diagramas do Irmão e Ingredientes da Mãe. Ao depositar, o item fica salvo permanentemente para a Casa da Família.
   * **Regra Absoluta:** O Baú **rejeita armas empunhadas**. A Morte alerta: *"Se depositar sua lâmina aqui, prosseguirá desarmado"*.
   * **Coleta de Armas nas Fases:** Estilo *Dead Cells*. Encontrou uma arma no chão, interagir substitui o equipamento empunhado e joga o antigo no chão. Não existe mochila de armas.

---

## 5. O Hub: A Cabana Rústica Medieval da Família & O Toque da Morte

A Cabana é o santuário protegido da anomalia temporal. Sua estética segue a fantasia medieval rústica clássica (estilo *Senhor dos Anéis* / Tolkien — vigas de carvalho escuro, lareira crepitante de pedra, fardos de feno, ferramentas de ferro forjado e ervas silvestres penduradas no teto).

O espaço é estruturado de forma linear e contínua em setores greybox com progressão natural de preparação do guerreiro:

```
[ Quarto do Guerreiro ] ─── [ Ervanária da Mãe ] ─── [ Forja do Irmão & Armas ] ─── [ Pátio dos Pets ] ─── [ Arco de Pedra / Morte ]
 (Despertar & Baú Skins)     (Caldeirão & Infusões)      (Bigorna & 3 Slots Armas)       (Cão & Gata)             (Modificadores & Run)
```

1. **O Quarto do Guerreiro (Despertar & Baú de Cosméticos):**
   * Fade suave abrindo na cama de madeira rústica e peles ao lado da lareira crepitante.
   * O guerreiro desperta do colapso temporal com vida a 100%, 1 frasco de infusão recarregado e Nível 1.
   * **Baú de Carvalho do Quarto (Skins & Capas):** Baú de roupas onde o jogador pode inspecionar e equipar mantos de lã, capas de viagem com capuz e túnicas costuradas pela Mãe.

2. **A Mãe (Ervanária Medieval, Caldeirão & Roupas da Família):**
   * **Regra Sagrada de Lore:** A Mãe e o Irmão **NÃO SABEM** que o guerreiro morre em um loop temporal (para eles, o herói acabou de acordar para sua rotina matinal normal de patrulha).
   * **Acesso & UI de Seleção Inicial (3 Botões Grandes com Cores Sólidas):**
     * Ao interagir com a Mãe (`RB` / clique), abre uma tela limpa com três botões/cards grandes:
       * **[ ELIXIRES DO DIA ] (O Randomizer Diário da Mãe):**
         * A Mãe ferve tachos artesanais frescos a cada despertar. Inicialmente oferece **2 elixires temporários** para a partida:
           1. *Elixir de Folha-de-Fogo:* +20% de dano no primeiro ataque desferido após uma esquiva/rolamento.
           2. *Caldo Revigorante:* Concede +1 carga extra inicial no Frasco de Chá (inicia a run com 2/2 cargas).
       * **[ CHÁS PERMANENTES ] (Upgrades por Ervas Duplicadas):**
         * Conforme o jogador resgata **Mudas / Feixes de Ervas Raras** nas ruínas (salvos no Baú Transtemporal), a Mãe aprimora permanentemente a linhagem:
           1. *Chá de Raiz-de-Pedra:* +15 HP Máximo fixo na linhagem por nível.
           2. *Chá de Camomila-da-Montanha:* +5% de eficácia na cura do Frasco por nível.
       * **[ ROUPAS & TÚNICAS ] (Personalização Cosmética):**
         * A Mãe costura e tinge tecidos com pigmentos naturais colhidos no vale. Permite alternar a paleta visual do herói:
           1. *Túnica do Viajante (Padrão):* Tecido cru/bege rústico com bordas marrom-terra.
           2. *Manto Carmesim da Mãe:* Túnica tingida em vermelho carmesim vibrante com bordas douradas.
   * **Diálogos de Fechamento da Mãe (Barks Afetivos e Brutos):**
     * *"Eu acordei com vontade de tomar esse daqui, ué!"*
     * *"Tá achando que eu sou sua empregada, menino?!"*
     * *"Bebe o que tá no fogo e não reclama, senão vai sair de estômago vazio!"*
     * *"Quer escolher cardápio? Vai procurar uma estalagem de luxo, folgado!"*
     * *"Vê se não vai se machucar por aí, ouviu?!"*

3. **O Irmão (A Forja do Aprendiz — Upgrades Diretos):**
   * **Acesso Direto à Forja:** Ao falar com o Irmão na bigorna (`RB` / clique), a interface abre **direto na lista de aprimoramentos de armas**, eliminando telas intermediárias.
   * **Aprimoramento por Receitas Duplicadas:**
     * *Espada Rústica:* Nível 1 (Dano Base: 15) -> Nível 2 requer 2 receitas repetidas.
     * *Arco de Caça:* Nível 1 (Dano Base: 12) -> Nível 2 requer 2 receitas repetidas.
   * **Diálogos de Fechamento do Irmão:**
     * *"Eu não sou uma fábrica, cara, sou só um!"*
     * *"Foi o que deu pra forjar antes do meio-dia, folgado!"*
     * *"Se você não perdesse minhas lâminas por aí, tinha mais opção!"*
     * *"Cobra menos e ajuda mais no fole da forja na próxima!"*
     * *"Volta inteiro, tá me ouvindo?"*

4. **A Galeria de Pedestais de Armamento (Substituindo o Armário/Baú):**
   * Em vez de um armário abstrato ou baú de menu, o arsenal fica **exposto fisicamente no cenário sobre 9 Pedestais de Pedra** organizados à direita da bigorna:
     * **6 Pedestais de Armas (Principais e Secundárias):**
       - *Pedestal 1:* **Espada Rústica** (Desbloqueado desde o início).
       - *Pedestal 2:* **Trancado** — *Requer descobrir 4 armas nas expedições (1/4).*
       - *Pedestal 3:* **Trancado** — *Requer derrotar 3 chefões diferentes (0/3).*
       - *Pedestal 4:* **Trancado** — *Requer derrotar 10 guardas de elite (0/10).*
       - *Pedestal 5:* **Trancado** — *Requer sugar 500 almas / essências de monstros (0/500).*
       - *Pedestal 6:* **Trancado** — *Requer derrotar 50 abominações do Caos (0/50).*
     * **3 Pedestais de Escudos (Slots de Defesa & Parry):**
       - *Pedestal 1:* **Broquel de Ferro** (Desbloqueado desde o início).
       - *Pedestal 2:* **Trancado** — *Requer realizar 3 aprimoramentos em escudos na Forja (0/3).*
       - *Pedestal 3:* **Trancado** — *Requer executar 25 parries perfeitos contra elites (0/25).*
   * **Fluxo Diegético de Equipar:**
     * O guerreiro caminha até o pedestal ativo e aperta `RB`:
       - 1ª Arma escolhida: equipa na **Mão Principal**.
       - 2ª Arma escolhida: equipa nas **Costas (Secundária)**.
       - Pedestal de Escudo: equipa no **Braço de Bloqueio/Parry**.
     * Pedestais trancados exibem silhueta escura e placa inscrita com o objetivo e progresso ao se aproximar.

5. **Sistema de Rastreio Global (Metaprogressão & Estatísticas da Linhagem):**
   * Centralizado no autoload `ProgressionManager`, gravando dados persistentes entre runs:
     * **Categorias Oficiais de Inimigos (`EnemyCategory`):**
       1. `UNDEAD` — Zumbis, esqueletos, mortos-vivos ressuscitados pela anomalia.
       2. `BEAST` — Criaturas e feras corrompidas da floresta (lobos, morcegos, javalis).
       3. `ABOMINATION` — Amálgamas grotescas e manifestações puras do Caos temporal.
       4. `HUMANOID` — Soldados imperiais, guardas de elite e mercenários corrompidos.
       5. `BOSS` — Portadores do Caos (guardiões dos selos de bioma).
     * **Métricas Rastreadas:**
       - Almas / Essências temporais absorvidas (`total_souls_collected`).
       - Abates por categoria de inimigo (`kills_by_category`).
       - Elites derrotados (`elite_kills_count`).
       - Chefes únicos derrotados (`bosses_defeated_list`).
       - Receitas e armas descobertas (`weapons_discovered_count`).
       - Upgrades realizados em escudos (`shield_upgrades_performed`).
       - Parries perfeitos bem-sucedidos (`perfect_parries_count`).
       - Mortes totais no ciclo (`total_deaths_count`).

5. **Os Pets da Cabana (Preta & Bela — Posições Dinâmicas a Cada Run):**
   * **A Cachorrinha (Preta — Dachshund / Salsichinha):** Fêmea de pelo preto brilhante/carvão, pernas curtas, corpo alongado, orelhas caídas e olhar carinhoso.
   * **A Gatinha (Bela — Siamês Cinza-Claro / Quase Branca):** Pelo curto e elegante (não felpuda), corpo claro/esbranquiçado com pontas (orelhas, focinho e cauda) em cinza suave.
   * **Comportamento Dinâmico:** A cada nova run / despertar, a Preta e a Bela sorteiam lugares aconchegantes diferentes para repousar entre a Cozinha e a Forja (ex: enroladas perto do fogo da lareira, embaixo da mesa de ervas, sobre uma pele de ovelha ao lado do fole ou cochilando perto do cesto de lenha).
   * **Interação:** O jogador pode se aproximar para fazer carinho (`[E] / [RB]`) com coração diegético, abanar de cauda e ronronar.

6. **A Atmosfera Visual da Casa (O Refúgio Feliz, Fofo e Colorido):**
   * O interior da cabana contrasta fortemente com a desolação sombria das ruínas externas:
   * **Paleta Quente & Viva:** Tons vibrantes de madeira acolhedora, luz âmbar da lareira, potes de cerâmica colorida, feixes de ervas verde-vivas, flores silvestres em jarras, mantas tecidas em tons de amarelo e terracota, e o brilho rubro da fornalha.
   * A casa passa uma sensação genuína de paz, afeto familiar e acolhimento fofo — o motivo pelo qual o guerreiro luta para proteger o santuário.

7. **O Arco de Pedra em Ruínas & A Manifestação Híbrida da Morte:**
   * **Regra Cromática Estrita da Morte:** Qualquer elemento visual ligado à Morte (névoa do portal, cartas de bênção, auras e tela de game over) utiliza obrigatoriamente a mesma paleta verde-esmeralda acinzentada do vórtice (`#2E5246` / `#6BBC9E` / `#080D0A`).
   * **Comportamento do Espectro Híbrido:**
     * *Em Repouso (distante):* O arco de pedra ancestral emana apenas a névoa viva verde-esmeralda rodopiando pelo solo.
     * *Ao Aproximar-se:* A névoa se adensa e dela **se condensa suavemente um espectro esbranquiçado sem pés**, de feições esqueléticas e manto etéreo que se dissolve na fumaça. A Morte projeta a janela **"O Toque da Morte"** com botões de cartas/modificadores para a run.
   * **2 Feitiços / Modificadores Iniciais do Protótipo:**
     1. *Onda Espectral:* O Parry Perfeito emite uma onda de choque que repele e desestabiliza inimigos ao redor.
     2. *Olhar da Ruína:* Causa +25% de dano contra qualquer inimigo que estiver atordoado (Stun).
   * **Diálogos Bem-Humorados e Sarcásticos da Morte (4 Variações):**
     * *"Tá achando que poder nasce em árvore? Para de morrer e vai matar os Portadores do Caos!"*
     * *"Eu sou a Morte, não uma feira livre. Derruba os Portadores do Caos se quiser coisa melhor!"*
     * *"Não sou loja de feitiço, mortal. Vai cobrar a alma dos Portadores do Caos pra mim!"*
     * *"Quer mais magia? Para de morrer à toa e vai arrancar a essência dos Portadores do Caos!"*
   * **Expansão do Pool via Derrota de Bosses:** Ao abater cada Portador do Caos, novos modificadores avançados entram permanentemente no sorteio do Toque da Morte.

8. **Diretriz de Greybox & Placeholders (Fase Atual):**
   * Enquanto a arte final pixel art não for desenhada, todos os elementos da casa (cenário, Mãe, Irmão, Cachorrinha, Gatinha e Espectro da Morte) são implementados como **placeholders geométricos limpos**, preservando proporções, paletas e áreas físicas de colisão.
   * Os NPCs nesta fase inicial atuam puramente como presenças físicas/cenográficas no ambiente, sem lógicas complexas de loja ou forja ativadas prematuramente.

---

## 6. Almas Estilhaçadas & Subida de Nível (O Toque da Morte Contínuo)

1. **Drop Físico com Sucção Magnética:**
   * Inimigos derrotados espirram estilhaços luminosos ciano-celestes que quicam no chão com gravidade leve.
   * A uma distância de ~90px (ou após 0.6s), os fragmentos aceleram suavemente em curva em direção ao peito do protagonista.
   * **Bônus Técnico (Alma Purificada):** Abates desferidos via **Parry Perfeito** ou **Contra-Ataque** dropam estilhaços dourados com **+25% de EXP bônus**.

2. **Subida de Nível & Janela do Toque da Morte:**
   * Ao preencher a barra de EXP e subir de nível:
     * O tempo congela instantaneamente com slow-motion dramático.
     * Surge a janela do **"Toque da Morte"**, oferecendo **3 modificadores aleatórios** de build para o jogador escolher 1.
     * Ao confirmar a escolha, a janela fecha e o jogador recebe **0.5s de invulnerabilidade protetora** com retomada suave do tempo, impedindo golpes surpresa.
   * O nível do jogador recalibra imediatamente a força e os Tiers dos monstros da sala (Tier 1 -> Tier 2 no Lv 4 -> Tier 3 no Lv 8).
