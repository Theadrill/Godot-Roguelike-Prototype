# TODO: Mapeamento de Sprites e Animações dos Estados do Jogador

> [!IMPORTANT]
> **REGRA OBRIGATÓRIA DO PROJETO:** Sempre que uma animação de personagem ou efeito de corte (*slash*) for concluída, atualizada ou quando surgirem novos estados/animações, este arquivo (`docs/TODO.md`) **DEVE ser atualizado imediatamente** antes do commit.

---

## 🔴 1. Estados que Ainda Caem no Placeholder Geométrico (`BodyPlaceholder` / Sem `play_animation`)
Nestes estados, como o estado anterior chama `stop_animation()` no `exit()` e o novo estado ainda não possui animação vinculada, o sprite do aventureiro some e aparece o retângulo colorido (`BodyPlaceholder`):

- [ ] **`WallJump` (`src/entities/player/states/wall_jump_state.gd`):**
  - Não chama `play_animation()` ao chutar a parede (cai no retângulo placeholder durante a subida até entrar no `Fall`). Pode usar o `jump` ou um sprite dedicado de salto na parede.
- [ ] **`Stagger` / Tomar Stun ou Guard Break (`src/entities/player/states/stagger_state.gd`):**
  - Chama apenas `player.set_crouched(true)` sem `play_animation()`, exibindo o retângulo placeholder achatado quando leva ataque vermelho ou quebra de guarda. Falta sprite de `hurt` / `stagger`.
- [ ] **`Heal` / Tomar o Chá da Mãe (`src/entities/player/states/heal_state.gd`):**
  - Não chama `play_animation()` e pisca a cor verde em `player.body_polygon`. Falta sprite de beber chá/poção (ou usar `channeling`).
- [ ] **`RangedAttack` com Arco (`Bow`) e Besta (`Crossbow`) (`src/entities/player/states/ranged_attack_state.gd`):**
  - O Cajado (`Staff`) já usa `channeling` e `cast`, mas quando equipado com **Arco** ou **Besta**, não chama `play_animation()`, caindo no retângulo placeholder.
- [ ] **`Death` / Morte (`src/entities/player/player.gd`):**
  - Não possui animação de morte (`die` / `death`) antes de o vórtice espiral cobrir a tela.

---

## 🟡 2. Estados e Ações que Reutilizam Outro Sprite como "Quebra-Galho" (Falta Sprite Dedicado)
Estes estados não mostram o retângulo colorido, mas estão esticando/achatando via código (`scale`) ou reaproveitando outro sprite:

- [ ] **`HardLanding` / Pouso Pesado de Grande Altura (`src/entities/player/states/hard_landing_state.gd`):**
  - Hoje toca `play_animation(&"idle")` e achata o nó `Visual` no código (`scale = Vector2(1.25, 0.55)`).
- [ ] **`GroundSlam` / Impacto Aéreo (`Baixo + Pulo` no ar) (`src/entities/player/states/ground_slam_state.gd`):**
  - Na descida usa `play_animation(&"roll")` (1 frame estático) e no impacto no chão usa `crouch` achatado via `scale` (`Vector2(1.45, 0.52)`).
- [ ] **Ataques Direcionais (`Cima`, `Baixo no Ar` e `Agachado`) (`src/entities/player/states/attack_state.gd`):**
  - Quando ataca segurando **Para Cima**, **Para Baixo no ar** ou **Agachado no chão**, o `if not is_upward and not is_downward` pula o `play_animation()`, fazendo o personagem cair no retângulo placeholder durante o golpe direcional.
- [ ] **Ataque Carregado (`is_charge_attack` — Segurar `X`) (`src/entities/player/states/attack_state.gd`):**
  - Durante o carregamento (*windup*), apenas rotaciona o `main_hand_socket` para `-65°` sem tocar animação dedicada no `PlayerSprite`.
- [ ] **Animações de Combate Aéreo / Slashes Restantes:**
  - [ ] **`air_attack2`** (segundo golpe aéreo caso seja adicionado futuramente).
  - [ ] **Slash dedicado do `air_attack3` (`slash_air_sword_3`)** (em implementação).

---

## 🟢 3. Estados que JÁ Têm Sprite Próprio Funcionando (`assets/player/adventurer/player_frames.tres`)
- [x] **`Idle`** (`idle` — 4 frames)
- [x] **`Run`** (`run` — 6 frames)
- [x] **`Jump`** (`jump` — 4 frames)
- [x] **`DoubleJump`** (`double_jump` — 4 frames de giro no ar)
- [x] **`Fall`** (`fall_from_jump` — 3 frames de transição + `fall` — 2 frames em loop)
- [x] **`Crouch`** (`crouch` — 4 frames)
- [x] **`Slide` / Esquiva** (`slide` — 2 frames)
- [x] **`WallSlide`** (`wall_cling` — 1 frame + `wall_slide` — 2 frames)
- [x] **`LedgeClimb`** (`corner_climb` — 5 frames)
- [x] **`Guard` / Escudo** (`block` — 3 frames + `block_loop` — 2 frames)
- [x] **`RangedAttack` (Magia/Cajado)** (`channeling` — 2 frames + `cast` — 4 frames)
- [x] **`Attack` (Chão)** (`attack1` + `slash_sword`, `attack2` + `slash_sword_2`, `attack3` + `slash_sword_3`)
- [x] **`Attack` (Ar)** (`air_attack1` + `slash_air_sword_1`, `air_attack3` corpo pronto)
