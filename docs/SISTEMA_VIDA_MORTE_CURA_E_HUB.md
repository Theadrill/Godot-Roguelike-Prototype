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

## 5. O Hub: A Casa da Família & O Toque da Morte

A Casa é um espaço seguro dividido em setores:

```
[ Tatame / Quarto ] ─── [ Cozinha da Mãe ] ─── [ Forja do Irmão ] ─── [ Baú de Equip. ] ─── [ Névoa da Morte / Saída ]
     (Despertar)             (Chás & Costura)          (Diagramas)            (3 Slots)           (Modificador & Run)
```

1. **O Despertar:**
   * Fade suave abrindo no tatame. Vida a 100%, frascos recarregados, Nível 1.

2. **A Mãe (Cozinha & Mesa de Costura):**
   * **Chás & Upgrades Permanentes:** Chás preparados com ervas misteriosas que aumentam atributos eternos do save (ex: +10 HP Máximo fixo).
   * **Elixires da Run (Acumulativos):** A Mãe prepara infusões temporárias antes da partida. O jogador pode tomar **múltiplos chás diferentes** e empilhar seus efeitos para aquela run específica.
   * **Mesa de Costura (Skins & Cosméticos):** Fabrica roupas e skins para o Protagonista, para a Mãe, para o Irmão e para os dois pets da casa com tecidos raros colhidos nas runs.

3. **O Irmão (A Forja do Aprendiz):**
   * Recebe os diagramas de armamentos salvos no Baú Transtemporal.
   * Como ferreiro aprendiz, adiciona novas armas e escudos básicos à sua coleção no Baú de Equipamentos.

4. **O Baú de Equipamentos da Casa (3 Slots Grandes):**
   * Ao abrir o baú, a interface exibe 3 seletores modulares:
     * **Slot 1 (MainHand):** Escolha da arma principal empunhada.
     * **Slot 2 (Secundária / Costas):** Escolha da arma secundária (arcos, adagas, etc.).
     * **Slot 3 (OffHand):** Escolha do escudo (broquel de parry, escudo de absorção).
   * Pressionar `Start` / `Confirmar` equipa o loadout e fecha o baú.

5. **Os Pets da Casa:**
   * A **Cachorrinha** e a **Gatinha** repousam pela casa. O jogador pode interagir para fazer carinho (`E` / `X`) e equipar roupinhas costuradas pela Mãe.

6. **A Névoa Esverdeada & "O Toque da Morte":**
   * À direita da casa, a névoa anuncia a presença da Morte.
   * Abre a janela **"O Toque da Morte"** com 3 modificadores aleatórios para a run.
   * Selecionado o modificador, o guerreiro entra na porta, a anomalia temporal se manifesta e a run no Bioma 1 tem início.

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
