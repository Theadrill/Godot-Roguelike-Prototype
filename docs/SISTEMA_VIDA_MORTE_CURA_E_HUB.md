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

2. **A Mãe (Ervanária Medieval, Caldeirão & Personalidade de Mãe):**
   * **Acesso & UI de Seleção Inicial (2 Botões Grandes):**
     * Ao interagir com a Mãe (`RB` / clique), a interface abre em uma tela limpa dividida em **dois botões/cards grandes**:
       * **[ ELIXIRES ] (O Randomizer Diário da Mãe):**
         * A Mãe ferve tachos artesanais frescos a cada novo despertar. Ela oferece **2 ou 3 opções sorteadas de elixires temporários** para você beber antes de sair (acumulam efeitos para a run).
         * **A Personalidade Direta & Hilária da Mãe:**
           * Protagonista: *"Mãe, eu queria aquele chá de [nome]..."*
           * Mãe: *"Eu acordei com vontade de tomar esse daqui, ué!"*
           * Mãe: *"Tá achando que eu sou sua empregada, menino?!"*
           * Mãe: *"Bebe o que tá no fogo e não reclama, senão vai sair de estômago vazio!"*
       * **[ CHÁS ] (Upgrades Permanentes por Ervas Duplicadas):**
         * Conforme o jogador resgata **Mudas / Feixes de Ervas Raras** nas ruínas (salvos no Baú Transtemporal), a Mãe aprimora permanentemente a linhagem da família:
           * *1º Feixe encontrado:* Desbloqueia o chá na coleção (Nível 1).
           * *Feixes duplicados encontrados em runs futuras:* Atuam como ingrediente de upgrade (Lv 2 requer 2 feixes repetidos; Lv 3 requer 4 feixes repetidos).
           * *Exemplos:* *Raiz-de-Pedra* (+15 HP fixo por nível), *Folha-de-Athelas* (+5% eficácia da Garrafa de Chá por nível).
   * **Barks Afetivos e Cuidadosos ao Fechar a Janela:**
     * *"Vê se não demora para voltar, meu filho."*
     * *"Leva um casaco, tá ventando lá fora!"*
     * *"Vê se não morre de novo, ouviu?!"*
     * *"Que os espíritos antigos te guardem."*

3. **O Irmão (A Forja do Aprendiz — Hub de Upgrades):**
   * **Acesso & UI de Seleção Inicial (2 Botões Grandes):**
     * Ao interagir com o Irmão na bigorna (`RB` / clique), a interface abre em **dois botões/cards grandes**:
       * **[ FORJA ] (Upgrades por Receitas Duplicadas):**
         * O Irmão é o mestre de upgrades. Não existem moedas ou lingotes artificiais: o aprimoramento é alimentado por **Receitas Repetidas** resgatadas nas fases e salvas no Baú Transtemporal:
           * *1ª Receita encontrada no mundo:* Desbloqueia a arma para sempre no acervo da família (Nível 1).
           * *Receitas duplicadas em runs futuras:* Servem como material de aprimoramento (ex: 2 receitas repetidas da mesma espada -> Nível 2 com +10% dano; 4 receitas -> Nível 3 com bônus de impacto).
           * *Zero lixo:* Nenhuma receita repetida encontrada nas fases é desperdiçada.
       * **[ COLEÇÃO ]:**
         * Catálogo visual de todas as armas, arcos e escudos já dominados pelo clã, mostrando o nível atual de maestria de cada um.
   * **Barks do Aprendiz ao Fechar a Janela:**
     * *"Essa lâmina vai cortar até pedra!"*
     * *"Traz mais aço se achar pelo caminho, mano."*
     * *"O fio dessa espada ficou perfeito."*

4. **O Baú de Equipamentos (O Randomizer do Irmão & Montagem de Loadout):**
   * Localizado ao lado da forja do Irmão.
   * **O Randomizer de Loadout & A Lore do Irmão:**
     * Para manter cada run estratégica e impedir que o jogador use sempre a mesma arma repetitiva, o Irmão não consegue manter todo o arsenal polido ao mesmo tempo:
       * **Protagonista:** *"Ué, só essas armas hoje?"*
       * **Irmão:** *"Eu não sou uma fábrica, cara, sou só um! Foi o que deu pra afiar e forjar antes de você acordar."*
     * A cada despertar, o Irmão disponibiliza **2 ou 3 opções sorteadas de Armas Principais** (do acervo desbloqueado), **2 de Secundárias** e **2 de Escudos**.
     * Se você aprimorou uma arma para o Nível 2 ou 3 na forja, sempre que ela for sorteada pelo irmão, ela já vem naquele nível aprimorado!
     * Ao confirmar a seleção, o guerreiro equipa o loadout e sai pronto para a batalha.

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
     * *Ao Aproximar-se:* A névoa se adensa e dela **se condensa suavemente um espectro esbranquiçado sem pés**, de feições esqueléticas e manto etéreo que se dissolve na fumaça. A Morte projeta a janela **"O Toque da Morte"** (3 bênçãos/modificadores aleatórios sorteados do pool desbloqueado para a run).
     * *Ao Confirmar & Partir:* O espectro se dissipa de volta na névoa pura, o herói cruza o limiar e a run no Bioma 1 tem início.
   * **Expansão do Catálogo via Derrota de Bosses:**
     * A variedade de cartas do Toque da Morte **não é comprada nem desbloqueada por grind**: ela é conquistada superando os grandes desafios do mundo!
     * O jogador começa com um **Pool Inicial Básico** (6 a 9 modificadores fundamentais de parry, esquiva, dano físico e estamina).
     * **Ao derrotar cada Boss do jogo:**
       * Um selo temporal da Morte é rompido.
       * A tela de triunfo do chefe exibe uma mensagem solene:
         * *"O ciclo se aprofunda... O pacto se expande."*
         * `[ Novos modificadores disponíveis no Toque da Morte! ]`
       * O pool permanente da Morte recebe novos arquétipos avançados e sinergias de alto impacto para enriquecer todas as runs futuras.

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
