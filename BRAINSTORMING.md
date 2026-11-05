# Brainstorming & Game Design Document (Protótipo)

Documento vivo de concepção do nosso protótipo de Roguevania 2D focado em combate visceral e fluidez de movimento (estilo Dead Cells).

---

## 🏛️ Pilar 1: Identidade, Nome e Premissa da História
> *Status: Definido*

### 1. Resumo da História (O Avatar da Morte & O Dia do Massacre)
Você é um rapaz comum, um "zé ninguém" sem treino militar, vivendo com sua família nos arredores de um vilarejo pacífico. No dia fatídico, o exército de um General tirânico invade a região em busca de poder profano. Você testemunha impotente a execução brutal de sua mãe e de seu irmão caçula, antes de ser atravessado e morto logo em seguida.

Nos confins do além, você é recebido pelo próprio **Deus da Morte**. A divindade revela que o General roubou um fragmento vital do domínio da Morte (uma relíquia capaz de distorcer tempo e mortalidade). Enfraquecido e incapaz de agir diretamente no plano mortal, o Deus da Morte faz um pacto com você: em troca de ser seu **Avatar** terreno para caçar o General e recuperar o que foi roubado, Ele concede a maldição/bênção de **reviver aquele mesmo dia indefinidamente**.

Ao acordar de volta na cama, você descobre que sua mãe e seu irmão ainda estão vivos no refúgio seguro de sua casa, sem memórias da tragédia. **A porta da frente é o limiar**: no momento exato em que você gira a maçaneta e pisa para fora, o dia do massacre recomeça, os invasores atacam, e a sua caçada se inicia.

---

### 2. A Casa da Família (O Hub Central / Progressão Metagame)
Em vez de um hub vazio ou abstrato, a própria casa é o coração do jogo entre uma tentativa (run) e outra:
* **A Mãe (A Grande Curandeira):**
  * Responsável pelos upgrades permanentes de sobrevivência: aumento de vida máxima, frascos de cura (poções), resistência a sangramento/veneno e regeneração.
* **O Irmão (O Jovem Promissor em Forja/Engenharia):**
  * Responsável pelos desbloqueios de armamento e suporte: estuda fragmentos de armas roubadas que você traz das incursões, aprimora taxas de durabilidade, forja coldres para carregar mais armas secundárias e cria modificadores de utilidade (gancho, botas com pulo duplo).
* **O Altar do Deus da Morte (Nos Fundos da Casa):**
  * Permite investir as essências/almas colhidas dos inimigos para desbloquear poderes de Avatar (habilidade de desaceleração de tempo na esquiva, corte espectral e auras de medo).

---

### 3. Integração Perfeita com o Gameplay Roguelike
* **O "Zé Ninguém" que Rouba Armas:** Como o protagonista não é um mestre espadachim e não tem armas próprias, o combate depende inteiramente do instinto de sobrevivência e do desarmamento. Você parte de mãos vazias (ou com uma ferramenta rudimentar) e **precisa roubar as lanças, arcos, espadas pesadas e armas temporais dos próprios invasores** que você derruba pelo caminho.
* **O Loop & A Cidade em Ruínas:** A cada morte, a Morte puxa você de volta para a sua cama. Toda vez que você abre a porta de casa, o vilarejo e as fortificações inimigas se reorganizam caoticamente devido às ondas de choque temporal causadas pela relíquia roubada pelo General.

---

### 4. Sugestões de Título para o Jogo:
1. **Death's Threshold** (O Limiar da Morte) — *Alude à porta de casa que divide a paz familiar do massacre.*
2. **Borrowed Dawn** (Alvorecer Emprestado) — *Foco no mesmo dia revivido e no poder que não pertence a ele.*
3. **Mortal Vessel** (Receptáculo Mortal) — *O Zé Ninguém servindo de avatar para uma divindade.*
4. **Before the Gate** / **Threshold** (Limiar) — *Simples, marcante e direto.*
5. **Reaper's Kin** (Parentela da Morte) — *Foco no laço familiar e no pacto com a morte.*

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
