# Brainstorming & Game Design Document (Protótipo)

Documento vivo de concepção do nosso protótipo de Roguevania 2D focado em combate visceral e fluidez de movimento (estilo Dead Cells).

---

## 🏛️ Pilar 1: Identidade, Nome e Premissa da História
> *Status: Em discussão / Definição inicial*

### O papel da história neste protótipo:
A história deve ser **ultra-enxuta (1 a 2 parágrafos)**, servindo apenas como pretexto forte e coeso para:
1. Justificar por que o protagonista morre e sempre acorda de volta no ponto de partida (o loop do roguelike).
2. Justificar por que as masmorras mudam de formato a cada run (geração procedural).
3. Justificar o combate violento e rápido contra aberrações/guardiões.

---

### Opções de Premissa e Título em Avaliação:

#### Opção A: *Hollow Spark* (A Faísca Oca)
* **Conceito**: Um autômato/golem descartado em um abismo industrial de mineração esquecido. Uma faísca de energia mística instável habita sua armadura enferrujada. Quando seu corpo é destruído, a faísca é expelida e reencarna em uma nova carcaça de sucata no fundo do poço, precisando escalar de volta à superfície cortando sentinelas corrompidas.
* **Vibe**: Máquinas enferrujadas, faíscas metálicas, masmorras de pedra e vapor.

#### Opção B: *BloodBound* / *Vessel* (O Receptáculo de Sangue)
* **Conceito**: O clássico pacto sombrio (estilo Dead Cells / Bloodborne). Uma gota de essência viva imortal que possui corpos de prisioneiros executados jogados nas catacumbas de um castelo imperial em quarentena. Cada morte dissolve a carne, e a essência parasita o próximo condenado na pilha para tentar romper os portões da fortaleza.
* **Vibe**: Gótico, espadas pesadas, sangue sombrio, alquimia e castelos em ruínas.

#### Opção C: *Rift Carver* (O Tecelão da Fenda)
* **Conceito**: Um guerreiro aprisionado em um colapso temporal em uma cidadela flutuante. Cada vez que ele é derrotado, a realidade fratura e o tempo retrocede para o início da fenda, reorganizando os cômodos da fortaleza de forma distorcida. Ele empunha lâminas capazes de cortar a própria matéria cósmica para tentar quebrar o ciclo.
* **Vibe**: Neon retrô / dark fantasy, fendas cósmicas, movimentação com cortes ultra-velozes.

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
