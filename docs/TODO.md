# TODO: Mapeamento de Sprites e Animações dos Estados do Jogador

> [!IMPORTANT]
> **REGRA OBRIGATÓRIA DO PROJETO:** Sempre que uma animação de personagem ou efeito de corte (*slash*) for concluída, atualizada ou quando surgirem novos estados/animações, este arquivo (`docs/TODO.md`) **DEVE ser atualizado imediatamente** antes do commit.

---

## 🔴 1. Estados que Ainda Caem no Placeholder Geométrico (`BodyPlaceholder` / Sem `play_animation`)
Nestes estados, como o estado anterior chama `stop_animation()` no `exit()` e o novo estado ainda não possui animação vinculada, o sprite do aventureiro some e aparece o retângulo colorido (`BodyPlaceholder`):

- [ ] **`RangedAttack` com Besta no Ar (`crossbow_air_attack`) (`src/entities/player/states/ranged_attack_state.gd`):**
  - Falta sprite e animação dedicada para o **disparo com Besta (`Crossbow`) no ar**.
- [ ] **`Death` / Morte (`src/entities/player/player.gd`):**
  - Não possui animação de morte (`die` / `death`) antes de o vórtice espiral cobrir a tela.

---

## 🟡 2. Estados e Ações Opcionais / Pausados
- [ ] **`air_attack2` (Opcional / Não utilizado no momento):**
  - Os Sets de Espada, Adaga e Machado agora usam `air_attack1` no ar (padrão econômico estilo Dead Cells), deixando `air_attack2` sem uso por enquanto.
- [x] **Slash dedicado do `air_attack3` (`slash_air_sword_3`)** — alinhado via GUIDE amarelo e sincronizado frame a frame com as fases do mergulho (`PREP`, `FALL_LOOP`, `IMPACT`, `RECOVERY`).

---

## 🟢 3. Estados que JÁ Têm Sprite Próprio ou Reaproveitado Funcionando (`assets/player/adventurer/player_frames.tres`)
- [x] **`Idle`** (`idle` — 4 frames)
- [x] **`Run`** (`run` — 6 frames)
- [x] **`Jump`** (`jump` — 4 frames)
- [x] **`WallJump`** (`jump` — reutilizando pose de subida do pulo, estilo Dead Cells)
- [x] **`DoubleJump`** (`double_jump` — 4 frames de giro no ar)
- [x] **`Fall`** (`fall_from_jump` — 3 frames de transição + `fall` — 2 frames em loop)
- [x] **`Crouch`** (`crouch` — 4 frames)
- [x] **`HardLanding`** (`crouch` — reutilizando pose agachada sem deformar pixels)
- [x] **`GroundSlam`** (`air_attack3` frames 1..3 na descida + `crouch` no impacto)
- [x] **`Slide` / Esquiva** (`slide` — 2 frames)
- [x] **`WallSlide`** (`wall_cling` — 1 frame + `wall_slide` — 2 frames)
- [x] **`LedgeClimb`** (`corner_climb` — 5 frames)
- [x] **`Guard` / Escudo** (`block` — 3 frames + `block_loop` — 2 frames)
- [x] **`Pickup` / Pegar Item** (`pickup` — frames `0, 2` do sheet 3-frames 83x62, armas guardadas nas costas/cintura)
- [x] **`Heal` / Tomar o Chá da Mãe** (`heal` — frames `0, 1` do sheet 3-frames 83x62, armas guardadas nas costas/cintura com pulso esmeralda)
- [x] **`RangedAttack` (Magia/Cajado)** (`channeling` — 2 frames + `cast` — 4 frames)
- [x] **`RangedAttack` (Arco / Chão)** (`bow_attack` — 7 frames com cadência contínua ciclando do frame 3 ao 6 ao segurar o botão, disparo no penúltimo frame e trava de movimento no chão estilo Dead Cells)
- [x] **`RangedAttack` (Arco / Ar)** (`bow_air_attack` — 6 frames no grid 83x62, puxada 0..3, disparo no penúltimo frame 4 e recuperação no frame 5)
- [x] **`RangedAttack` (Besta / Chão)** (`crossbow_attack` — 3 frames: mira 0, disparo 1 e recuperação 2)
- [x] **`Attack` (Chão)** (`attack1` + `slash_sword`, `attack2` + `slash_sword_2`, `attack3` + `slash_sword_3`)
- [x] **`Attack` (Ar)** (`air_attack1` + `slash_air_sword_1`, `air_attack3` + `slash_air_sword_3` para plunge do Martelo)
- [x] **Ataques a partir de `Crouch`, `Cima` ou `Baixo no ar` (sem plunge)** — levantam/normalizam automaticamente para o combo padrão (bloqueando ataque sob teto baixo via `ceiling_check`).
- [x] **Ataque Carregado (`is_charge_attack`)** — segura o frame configurável (`charge_ready_animation` / `charge_ready_frame`) com sockets do Tool e `EnergizeProfile` elemental.
- [x] **`Stagger` / Tomar Dano (`hurt`)** — 3 frames com *Last-Frame Hold* via `Hitbox.stagger_duration` (ou fallback `PERILOUS`), *post-hit i-frames* e *flinch* rápido no frame `0` para ataques leves.

---

## 💡 4. Ideias Futuras / Modificadores Elementais
- [ ] **Modificador de Chão Queimando (DoT de Fogo):**
  - Criar um afixo/modificador futuro para armas ou habilidades de Fogo que deixe a faixa do chão queimando por mais tempo após o impacto (com área de dano contínuo), diferente do efeito atual que dura apenas alguns frames para feedback visual sem parecer dano contínuo.
