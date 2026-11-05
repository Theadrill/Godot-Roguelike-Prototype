# Brainstorming & Game Design Document (Protótipo)

Documento vivo de concepção do nosso protótipo de Roguevania 2D focado em combate visceral e fluidez de movimento (estilo Dead Cells).

---

## 🏛️ Pilar 1: Identidade, Nome e Premissa da História
> *Status: Definido*

### 1. Resumo da História (Traição & Vingança Temporal)
Você era o mais leal comandante da guarda de elite de uma ordem tirânica. Durante um golpe orquestrado por seus próprios irmãos de armas, você foi apunhalado pelas costas, desarmado e jogado para morrer nas profundezas de uma cidadela fortaleza.

Com seu último suspiro, você conseguiu agarrar e cravar no peito o artefato temporal que seu carrasco empunhava: uma lâmina/ampulheta forjada com a essência do tempo (*A Lâmina Cronos*). 

O artefato fundiu-se com a sua alma, criando uma maldição de ódio eterno: **você não pode morrer definitivamente**. Cada vez que seu corpo sucumbe aos ferimentos, o artefato colapsa o tempo ao redor e puxa sua consciência de volta para o momento da traição nas masmorras. 

Para alcançar os traidores no topo da fortaleza, você não tem armas próprias: você precisa **desarmar, roubar e dominar as armas temporais e equipamentos dos próprios guardas e comandantes que o traíram**, usando o poder do tempo roubado deles contra eles mesmos.

---

### 2. Justificativas Narrativas para o Gameplay (O "Porquê" das Mecânicas)
* **O Loop Roguelike (Morte & Retorno):** A arma temporal alojada em você rebobina o tempo no instante da sua morte física, jogando você de volta à cela de execução, mas mantendo suas memórias e o ódio acumulado.
* **O Mapa Procedural:** A manipulação constante do fluxo temporal pela fortaleza distorce a arquitetura do castelo a cada rebobinada, fazendo com que as salas, corredores e patrulhas mudem de posição.
* **Roubo de Armas dos Inimigos:** Como você começa de mãos vazias, a mecânica central de loot é o desarmamento: derrubar sentinelas, arrancar suas lanças, adagas ou arcos temporais e usar suas propriedades até que elas se desgastem ou você encontre uma arma mais mortal.
* **Habilidades de Tempo:** A mecânica de esquiva e hitstop ganha peso narrativo: desacelerações de tempo momentâneas (bullet time em esquivas perfeitas), cortes rápidos e parry com eco temporal.

---

### 3. Sugestões de Título para o Jogo:
1. **Stolen Seconds** (Segundos Roubados) — *Foco no roubo de armas e no tempo emprestado.*
2. **Chrono Vendetta** — *Direto ao ponto: vingança rápida e temporal.*
3. **Borrowed Edge** (Lâmina Emprestada) — *Ênfase no fato de que todas as armas são tomadas dos traidores.*
4. **Hourglass Betrayed** — *Tom mais sombrio e épico.*

---

## ⚔️ Pilar 2: Mecânicas de Gameplay & Game Feel
> *(A ser detalhado após fecharmos o Pilar 1)*
* Máquina de estados do jogador (Andar, Correr, Pulo, Pulo Duplo, Rolamento/Dash, Combo 3-hits).
* Regras de ouro de satisfação (Coyote time, Jump buffer, Hitstop, i-frames).
* Sistema de combate (Hitboxes/Hurtboxes, knockback, afixos de armas).

---

## 🗺️ Pilar 3: Level Design & Estrutura das Fases
> *(A ser detalhado na sequência)*
* Grade de tiles e métricas de salto (altura x distância).
* Sistema híbrido de salas/chunks pré-montadas conectadas via walker.
* Salas de combate trancadas com ondas de inimigos vs. corredores de travessia.
