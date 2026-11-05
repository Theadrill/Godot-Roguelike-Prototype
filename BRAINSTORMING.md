# Severed Dawn - Game Design Document (Protótipo)

Documento vivo de concepção e especificações técnicas do protótipo **Severed Dawn**, um Roguevania 2D focado em combate visceral, fluidez de movimentação e impacto (estilo Dead Cells).

---

## 🏛️ Pilar 1: Identidade, Nome e Premissa da História
> *Status: OFICIALIZADO*

* **Título Oficial**: **Severed Dawn** (Alvorecer Rompido)
* **Verificação de Copyright**: 100% verificado e livre em lojas de jogos (Steam/Itch/Consoles), livros (Amazon/Goodreads), filmes (IMDb) e marcas registradas (USPTO).

### 1. Resumo da Premissa
Você é um rapaz comum, sem treino militar, vivendo com sua mãe (uma renomada curandeira) e seu irmão mais novo (um promissor criador de equipamentos) nos arredores de um vilarejo pacífico. No dia fatídico, o exército de um General tirânico invade a região em busca de uma relíquia divina. Você assiste impotente à execução brutal de sua mãe e de seu irmão antes de ser morto logo em seguida.

No além, você é recebido pelo próprio **Deus da Morte**. A divindade revela que o General roubou um fragmento vital do domínio da Morte. Enfraquecido e incapaz de agir diretamente no plano mortal, o Deus da Morte faz um pacto com você: ser seu **Avatar** terreno para caçar o General e recuperar o que foi roubado, em troca de **reviver aquele mesmo dia indefinidamente**.

Ao acordar de volta na cama, sua família está viva e salva dentro de casa. **A porta da frente é o limiar**: no segundo em que você gira a maçaneta e pisa para fora, o dia do massacre recomeça, a invasão explode e sua missão tem início.

### 2. A Casa da Família (O Santuário Limiar & Metaprogressão)
* **A Lore do Refúgio Temporal:** A casa está protegida do fluxo do espaço/tempo como parte da barganha com a Morte. Enquanto o mundo exterior reseta no dia do massacre, **o interior da casa retém memórias, conhecimentos e construções**. É uma bolha segura que só é rompida quando a maçaneta da porta da frente é girada para o exterior. Novos sobreviventes e NPCs resgatados nas runs encontram refúgio na casa, expandindo os serviços disponíveis.
* **O Irmão (O Aspirante a Forjador):**
  * Sendo apenas um jovem aprendiz, tudo o que ele cria inicialmente é rústico e improvisado (lâminas brutas, tacos reforçados, arcos simples).
  * **Projetos de Equipamentos (Blueprints):** Inimigos de elite e baús dropam diagramas e plantas militares. Ao entregá-los ao irmão, ele estuda a engenharia dos invasores e aprende a forjar novas bases de armas e equipamentos utilitários permanentemente.
* **A Mãe (A Curandeira):**
  * Desenvolve elixires e poções que concedem vantagens antes de cruzar a porta.
  * **Ingredientes e Reagentes:** A mãe precisa de ervas medicinais, extratos de monstros e minerais raros (coletados nas fases ou dropados por inimigos) para preparar frascos com mais cargas, curas instantâneas, antídotos ou elixires de dano.
* **O Toque da Morte (Encantamento & Ascensão):**
  * As armas rústicas do irmão ganham vida pelo poder do Deus da Morte. Conforme o jogador progride e sobe de nível (investindo a essência/almas colhidas), a Morte aplica encantamentos cada vez maiores: bônus de dano, sangramento, velocidade de ataque, afixos místicos e habilidades ativas especiais.

---

## ⚔️ Pilar 2: Gameplay, Mecânicas de Combate & Game Feel
> *Status: Em Definição*

### 1. Física e Movimentação ("Dead Cells Feel")
A movimentação deve dar ao jogador sensação de agilidade máxima e controle absoluto:

* **Controle Horizontal Instantâneo**:
  * Aceleração para a velocidade máxima em apenas ~0.08s.
  * Parada imediata sem deslizes desnecessários ao soltar o direcional.
* **Pulo com Altura Variável (Variable Jump)**:
  * Toque rápido no botão: salto curto (pulo rápido para desviar de flechas/lâminas baixas).
  * Segurar o botão: alcance da altura máxima do salto.
* **Coyote Time (Tolerância de Borda)**:
  * 0.12s (aprox. 7 frames a 60 FPS) após sair da borda de uma plataforma onde o comando de pulo ainda é aceito.
* **Jump Buffering (Fila de Pulo)**:
  * 0.12s antes de tocar o chão para registrar o comando e disparar o pulo no primeiro frame de aterrissagem.
* **Rolamento com Esquiva (Dodge Roll)**:
  * Arrancada horizontal ágil que atravessa inimigos e projéteis.
  * **i-frames (Quadros de Invulnerabilidade)**: Ativos durante 70% da duração da esquiva.
  * **Cancelamento de Animação**: O rolamento pode interromper a recuperação de ataques normais, permitindo jogadas de reação rápida.

---

### 2. Ponto 1: Origem e Sistema das Armas (DEFINIDO)
* **Base Rústica (O Irmão Aspirante):**
  * O jogador inicia cada run escolhendo entre as armas base criadas pelo irmão (espada de treino, adaga de caça, lança tosca).
  * Novas armas e ferramentas são desbloqueadas permanentemente ao encontrar **Projetos de Equipamentos (Blueprints)** nas fases e entregá-los ao irmão no Santuário.
* **O Toque Mágico da Morte (Encantamentos & Sinergias):**
  * As armas físicas do irmão servem de catalisador para o poder da Morte.
  * Conforme você progride e sobe de nível (investindo essências na Morte), desbloqueiam-se graus mais altos de encantamentos: dano necrótico, sangramento, velocidade aumentada e habilidades ativas.
* **Preparações da Mãe (Frascos & Elixires):**
  * Coleta de ervas e reagentes nas fases para a mãe preparar poções de cura com mais cargas e elixires de bônus temporários antes de abrir a porta.

---

### 3. Ponto 2: Sistema Tático de Defesa & Contra-Ataque (O Sistema dos 3 Sinais)
Inspirado na legibilidade visual de *Assassin's Creed* com a mecânica de precisão rítmica de *Gears of War* (Active Reload) e a intensidade de *Sekiro*:

#### Tabela de Tipos de Ataques Inimigos:
| Sinal Visual | Tipo de Golpe | Interrupção por Corte? | Resposta do Jogador (Mecânica de Defesa) |
| :---: | :---: | :---: | :--- |
| **Sem Sinal (Normal)** | Golpe padrão | **SIM** (O jogador corta e cancela o ataque do mob) | Corte agressivo, esquiva ou bloqueio simples. |
| **Amarelo (Pesado)** | Golpe forte | **NÃO** (Inimigo tem hyper-armor durante o golpe) | **Sistema de 3 Níveis de Resposta:**<br>• *Nível 1 (Parry Perfeito):* Nega 100% do dano, atordoa o monstro (*stagger*) e abre janela para contra-ataque crítico.<br>• *Nível 2 (Bloqueio Simples):* Absorve a maior parte do dano (toma apenas 15% de *chip damage* de impacto) e empurra o jogador.<br>• *Nível 3 (Falha / Bloqueio Atrasado):* Toma dano alto e sofre quebra de postura momentânea. |
| **Vermelho (Perilous)** | Golpe letal | **NÃO** | **Alta Ameaça (Proibido Bloquear):**<br>• *Segurar Escudo:* Proibido. A guarda é esmagada instantaneamente $\rightarrow$ dano completo + estado atordoado/imóvel.<br>• *Respostas Válidas:* **Parry Perfeito** (arriscado, alto reflexo, recompensa massiva) OU **Rolamento com i-frames** (opção segura de reposicionamento). |

---

### 4. Roadmap de Produção em Duas Fases (Engenharia Segura):
* **Fase 1 (Protótipo Imediato):** 
  * Mobs têm os sinais visuais (Amarelo e Vermelho).
  * Como a defesa inicial do jogador é o **Rolamento**, o rolamento é a resposta universal para escapar dos golpes Amarelos e Vermelhos sem precisar de escudo no primeiro dia.
* **Fase 2 (A Forja do Escudo do Irmão):** 
  * O irmão forja o primeiro broquel/escudo de madeira.
  * Implementação da mecânica completa: botão de guarda, janela de Parry (0.12s), chip damage e quebra de postura contra golpes vermelhos.

---

## 🗺️ Pilar 3: Level Design & Estrutura das Fases
> *(Próximo passo após fecharmos o Pilar 2)*
* Métricas da grade (16x16 ou 32x32) e proporção de salto.
* Chunks procedurais de combate, corredores e salas secretas.
* Geração do Vilarejo invadido e subida até a Fortaleza.
