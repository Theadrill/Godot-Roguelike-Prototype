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

### 3. O "Juice" e Peso Visceral dos Golpes
* **Hitstop (Micro-congelamento)**: Pausa de 0.04s a 0.07s na animação ao conectar o golpe na carne/armadura do inimigo, dando sensação de peso físico.
* **Hit-Flash**: O sprite do inimigo pisca em branco sólido por 0.08s ao levar dano.
* **Camera Shake (Trauma Base)**: Tremor de tela baseado em estresse decrescente (`trauma * trauma`).
* **Combo de 3 Golpes**:
  1. *Hit 1*: Corte horizontal rápido.
  2. *Hit 2*: Corte diagonal rápido em sentido oposto.
  3. *Hit 3 (Finisher)*: Estocada pesada ou corte vertical descendente com alto knockback e hitstop acentuado.

---

## 🗺️ Pilar 3: Level Design & Estrutura das Fases
> *(Próximo passo após fecharmos o Pilar 2)*
* Métricas da grade (16x16 ou 32x32) e proporção de salto.
* Chunks procedurais de combate, corredores e salas secretas.
* Geração do Vilarejo invadido e subida até a Fortaleza.
