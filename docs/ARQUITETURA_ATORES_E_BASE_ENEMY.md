# Levantamento Arquitetural Completo do Projeto & Plano de Padronização (Industry Standard)

> [!IMPORTANT]
> ## OBJETIVO DESTE DOCUMENTO
> Este documento consolida a **Auditoria Técnica Completa** de todos os subsistemas de **Severed Dawn** (`entities`, `combat`, `world`, `ui`, `core` e `tools`) e estabelece o roteiro em **Fases Testáveis** para elevar o repositório ao padrão de engenharia da indústria (*Dead Cells / Motion Twin*, *Hollow Knight*, *Nine Sols*), culminando no guia definitivo de criação de novos scripts referenciado como **Regra de Ouro** em [`docs/REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md).

---

## 1. Auditoria Global do Projeto (Por Subsistema)

### 1.1. Subsistema de Inimigos (`src/entities/enemies/`)
* **Duplicação Massiva (~70%):** [`soldier.gd`](../src/entities/enemies/melee/soldier/soldier.gd) (425 linhas) e [`archer.gd`](../src/entities/enemies/ranged/archer/archer.gd) (366 linhas) duplicam `enum CooldownBehavior`, todos os `@export` de Stats/Percepção/Tiers/Respawn, `apply_tier_by_level()`, `can_step_forward()`, `can_step_backward()`, `has_line_of_sight_to()`, `show/hide_telegraph()`, `on_attack_blocked()`, shader de `hit_flash` e `respawn()`.
* **Sensores Espalhados em 4 Lugares:**
  * `Archer` usa 5 nós `RayCast2D` na cena [`archer.tscn`](../src/entities/enemies/ranged/archer/archer.tscn) sincronizados manualmente no flip.
  * `Soldier` usa `PhysicsRayQueryParameters2D` em `soldier.gd`, mas [`soldier/states/patrol_state.gd`](../src/entities/enemies/melee/soldier/states/patrol_state.gd) e [`soldier/states/chase_state.gd`](../src/entities/enemies/melee/soldier/states/chase_state.gd) reescrevem `_is_at_ledge()`, `_is_hitting_wall()` e `_has_los_to_player()` por conta própria.
* **Estados Idênticos Duplicados:** [`soldier/states/death_state.gd`](../src/entities/enemies/melee/soldier/states/death_state.gd) e [`archer/states/death_state.gd`](../src/entities/enemies/ranged/archer/states/death_state.gd) são 98% idênticos.
* **3 Bugs Silenciosos Encontrados:**
  1. `Archer.apply_tier_by_level()` não possui o bloco `if active_tier >= 3:` (Archers Tier 3 usam atributos de Tier 2).
  2. `Soldier.update_facing()` reseta `visual.scale.x = ±1.0`, apagando a escala `1.15x` de Elite no primeiro giro de patrulha.
  3. `Archer` não implementa `apply_parry_stun()`.

---

### 1.2. Subsistema do Jogador & Equipamentos (`src/entities/player/` & `src/combat/`)
* **`Player` como *God Object* (1.502 linhas):** [`player.gd`](../src/entities/player/player.gd) mistura 5 domínios distintos no mesmo arquivo:
  1. Física de movimentação, *coyote/buffer*, *ledge climb*, *Life Rally* e saúde.
  2. Rig visual de equipamentos e sincronização frame a frame de 6 sockets (~350 linhas).
  3. Controlador de VFX de combate (*Slash VFX*, shader/partículas de *Energize*, impacto de chão e *Pickup Burst* — ~220 linhas).
  4. Detecção de arquétipo de arma por inspeção de string (`_detect_weapon_type_string`: `if "dagger" in res_path...`) em vez de propriedade tipada no `WeaponData`.
  5. Atalhos de debug (`T`, `Y`, `2`, `3`) acoplados direto no `_unhandled_input` do herói.
* **Código Morto (Dead Code — 347 linhas):** [`src/entities/player/weapon_socket_config.gd`](../src/entities/player/weapon_socket_config.gd) (`class_name WeaponSocketConfig`) não é referenciado em nenhum lugar do projeto (foi substituído por `WeaponSocketProfile` `.tres`), mas ainda é compilado globalmente.
* **Ferramenta Crítica de Calibração ([`src/tools/weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd) — 1.304 linhas):**
  * O calibrador `@tool` lê e salva diretamente em `WeaponSocketProfile` (`.tres` em `socket_profiles/`), `WeaponData` (offsets/scales por step e por frame) e `AttackSetData` / `ComboStepData`.
  * Embora não instancie `player.gd` diretamente, ele assume **paridade matemática 1:1** com a cena [`player.tscn`](../src/entities/player/player.tscn) e os cálculos de offset/flip/escala do jogador (descrito no contrato abaixo na Fase 4).

---

### 1.3. Subsistema de Mundo & Interações (`src/world/`)
* **Falta de Componente Único de Interação (Violação da Regra 9):**
  * [`family_house.gd`](../src/world/hub/family_house.gd) (Baú, Rack, Mãe, Irmão, Portal), [`weapon_pedestal.gd`](../src/world/hub/weapon_pedestal.gd) e [`pickup_item.gd`](../src/world/items/pickup_item.gd) reimplementam manualmente a detecção de proximidade (`body_entered` / `body_exited`), clique de mouse (`input_event`) e tecla `interact`.

---

### 1.4. Subsistema de UI, Hub & Localização (`src/ui/` & `src/core/`)
* **Violações da Regra 10 (Strings Hardcoded em Português fora do `translations.csv`):**
  1. [`src/ui/hud.gd`](../src/ui/hud.gd): `"⚔️ INIMIGOS: TIER %d [%s] - LV %d (Tecla T)"`, `"● O SANGUE CESSA..."`, `"● ESCUDO BLOQUEADO: %.1fs"`, `"● ESCUDO EM GUARDA"`, `"● ESCUDO PRONTO"`, `" [REPULSÃO ATIVA]"`.
  2. [`src/world/hub/weapon_pedestal.gd`](../src/world/hub/weapon_pedestal.gd): `"Trocou escudo: "`, `"Escudo Equipado: "`, `"Escudo guardado no pedestal."`, `"Pedestal Vazio."`, `"Equipado na mão: "`, `"Equipado nas costas: "`, `"Trocou de arma: "`, `"Arma guardada no pedestal."`, `"[Trancado] "`.
  3. [`src/core/progression_manager.gd`](../src/core/progression_manager.gd): Dicionário `WEAPON_DISPLAY_NAMES` e todas as strings de `get_weapon_pedestal_condition_text()` / `get_shield_pedestal_condition_text()`.
  4. [`src/ui/hub/mother_dialog_ui.gd`](../src/ui/hub/mother_dialog_ui.gd) e [`src/ui/hub/brother_forge_ui.gd`](../src/ui/hub/brother_forge_ui.gd): `"Nível "`, `"Feixes: "`, `"Dano: "`, `"Receitas Repetidas: "`.
  5. [`src/entities/player/player.gd`](../src/entities/player/player.gd): `"RECRUTA"`, `"VETERANO"`, `"ELITE"`.
* **Acoplamento de Modais no `PauseMenuUI`:**
  * [`pause_menu_ui.gd`](../src/ui/pause/pause_menu_ui.gd) faz `find_child("MotherDialogUI")`, `find_child("BrotherForgeUI")`, `find_child("TouchOfDeathUI")` e `find_child("DebugMetricsPanel")` nominalmente. Usar o grupo `"modal_ui"` desacopla o menu de pausa de qualquer nova janela futura.

---

## 2. Arquitetura Alvo do Projeto (Visão Macro)

```mermaid
flowchart TB
    subgraph Core["Camada 1: Core & Data (Resources .tres + Autoloads)"]
        CSV["translations.csv (100% i18n via tr())"]
        Prog["ProgressionManager (Save AES-256 + Metas)"]
        Data["WeaponData / ShieldData / AttackSetData / ComboStepData"]
    end

    subgraph Actors["Camada 2: Entidades & Componentes"]
        BaseEnemy["BaseEnemy (CharacterBody2D)\n- Sensores Stateless (PhysicsServer)\n- Tiers 1..3 + Elite + Telegraph 3 Sinais\n- HitFlash + ParryStun + Respawn"]
        Soldier["Soldier extends BaseEnemy"]
        Archer["Archer extends BaseEnemy"]
        EnemyDeath["EnemyDeathState (Compartilhado)"]

        Player["Player (CharacterBody2D)\n- Física, Movimento, FSM & Sobrevivência"]
        PlayerRig["PlayerEquipmentRig (Sub-controlador de Sockets & Drop)"]
        PlayerVFX["PlayerCombatVFX (Sub-controlador de Slash, Energize & Pickup)"]
    end

    subgraph UIWorld["Camada 3: Mundo & UI Desacoplados"]
        ModalGroup["Grupo 'modal_ui' (Mother, Brother, Death, DebugMetrics)"]
        PauseUI["PauseMenuUI (Consulta grupo 'modal_ui' sem acoplamento)"]
    end

    BaseEnemy --> Soldier
    BaseEnemy --> Archer
    EnemyDeath -.-> Soldier
    EnemyDeath -.-> Archer
    Player --> PlayerRig
    Player --> PlayerVFX
    Data --> PlayerRig
    CSV --> UIWorld
    CSV --> Actors
    ModalGroup --> PauseUI
```

---

## 3. Plano de Execução Passo a Passo (6 Fases Testáveis)

Cada fase será executada individualmente, validada via `Godot_v4.7.2-stable_win64_console.exe --headless --editor --quit --path . 2>&1` e testada pelo PO antes de avançar.

### 📦 FASE 1 — Fundação `BaseEnemy` & Estado Compartilhado `EnemyDeathState` *(Concluída)*
* **O que foi feito:**
  1. Criado [`src/entities/enemies/base_enemy.gd`](../src/entities/enemies/base_enemy.gd) (`class_name BaseEnemy extends CharacterBody2D`) unificando Stats, Tiers 1–3, Elite (`1.15x`), `update_facing()`, Telegraph dos 3 sinais, `advance_attack_cycle()`, `apply_parry_stun()`, `on_attack_blocked()`, `hit_flash`, `respawn()` e sensores espaciais stateless (`can_step_forward`, `can_step_backward`, `is_at_ledge`, `is_hitting_wall`, `has_line_of_sight_to`, `find_player`).
  2. Criado [`src/entities/enemies/states/enemy_death_state.gd`](../src/entities/enemies/states/enemy_death_state.gd) (`class_name EnemyDeathState extends State`) unificando a lógica de morte, recompensa no `ProgressionManager` e respawn.
* **Critério de Teste (Fase 1):** Compilação headless limpa com registro de `BaseEnemy` e `EnemyDeathState`.

---

### 🏹 FASE 2 — Migração do `Archer` para `BaseEnemy` & Limpeza de `archer.tscn` *(Concluída)*
* **O que foi feito:**
  1. Refatorado [`archer.gd`](../src/entities/enemies/ranged/archer/archer.gd) para herdar de `BaseEnemy` (~366 $\rightarrow$ ~110 linhas).
  2. Removidos os 5 nós `RayCast2D` (`WallCheck`, `LedgeCheck`, `BackWallCheck`, `BackLedgeCheck`, `SightRay`) de [`archer.tscn`](../src/entities/enemies/ranged/archer/archer.tscn).
  3. Apontado o nó `StateMachine/Death` do `Archer` para `EnemyDeathState` e removido código duplicado nos estados do `Archer`.
* **Critério de Teste (Fase 2):** No `movement_gym`, o `Archer` patrulha na plataforma `Step4` sem cair, faz *kite*, atira com os 3 sinais, sofre *Parry Stun*, morre/renasce e escala corretamente para o **Tier 3** (`T`).

---

### ⚔️ FASE 3 — Migração do `Soldier` para `BaseEnemy` & Limpeza dos Estados Melee *(Concluída)*
* **O que foi feito:**
  1. Refatorado [`soldier.gd`](../src/entities/enemies/melee/soldier/soldier.gd) para herdar de `BaseEnemy` (~425 $\rightarrow$ ~140 linhas).
  2. Limpos [`soldier/states/patrol_state.gd`](../src/entities/enemies/melee/soldier/states/patrol_state.gd) e [`soldier/states/chase_state.gd`](../src/entities/enemies/melee/soldier/states/chase_state.gd) para usar os sensores de `BaseEnemy` (eliminando `_is_at_ledge`, `_is_hitting_wall`, `_can_see_player`, `_get_player`, `_has_los_to_player` duplicados).
  3. Apontado `StateMachine/Death` do `Soldier` para `EnemyDeathState` e removidos os scripts `death_state.gd` duplicados de `soldier` e `archer`.
* **Critério de Teste (Fase 3):** Combate completo contra `Soldier` e `Archer`, verificando que o `Soldier` Elite mantém a escala `1.15x` ao virar de lado, respeita stunlock vs. hyper-armor e contabiliza kills/almas.

---

### 🗡️ FASE 4 — Modularização do `Player`, Tipagem em `WeaponData` & Remoção de Dead Code *(Concluída)*
* **O que foi feito:**
  1. Removido o arquivo morto [`src/entities/player/weapon_socket_config.gd`](../src/entities/player/weapon_socket_config.gd) (347 linhas não utilizadas).
  2. Adicionado `get_archetype_id() -> String` diretamente em [`src/combat/weapon_data.gd`](../src/combat/weapon_data.gd).
  3. Extraído o gerenciamento de sockets e drop de equipamentos na morte para [`src/entities/player/player_equipment_rig.gd`](../src/entities/player/player_equipment_rig.gd) (`class_name PlayerEquipmentRig`).
  4. Extraído o gerenciamento de *Slash VFX*, *Energize* e *Pickup VFX* para [`src/entities/player/player_combat_vfx.gd`](../src/entities/player/player_combat_vfx.gd) (`class_name PlayerCombatVFX`), mantendo todas as assinaturas públicas em `player.gd` como fachadas intactas para compatibilidade 100% com os estados e o `WeaponSocketCalibrator`.

#### Contrato de Invariância e Compatibilidade 100% com o `WeaponSocketCalibrator` (`src/tools/weapon_socket_calibrator.gd`)
Durante e após a modularização do `Player`, os contratos abaixo **NÃO podem ser alterados** para garantir que futuras calibrações no [`weapon_socket_calibrator.tscn`](../src/tools/weapon_socket_calibrator.tscn) continuem refletindo exatamente o jogo:
1. **Dependências de Recursos Compartilhados (Imutáveis):**
   * `WeaponSocketProfile` (`get_frame_data`, `get_back_frame_data`, `set_hand_custom_data`, `set_back_frame_data`) nos perfis `res://src/entities/equipment/socket_profiles/*.tres`.
   * `WeaponData` (`get_socket_profile`, `get_step_total_slash_offset`, `get_step_total_slash_scale`, `get_step_slash_flip_h`, `get_step_slash_flip_v`, `get_step_slash_animation`, `make_slash_frame_key`, `slash_offset`, `slash_scale`, `slash_step_offsets`, `slash_step_scales`, `slash_frame_offsets`, `slash_frame_scales`).
   * `AttackSetData` e `ComboStepData` (`get_frame_slash_offset`, `get_frame_slash_scale`, `step_frame_slash_offsets`, `step_frame_air_slash_offsets`, `step_frame_slash_scales`, `step_frame_air_slash_scales`).
2. **Paridade Matemática 1:1 entre `WeaponSocketCalibrator` e `PlayerEquipmentRig` / `PlayerCombatVFX`:**
   * Manter a mesma hierarquia e nomes dos 6 sockets sob `Visual` em [`player.tscn`](../src/entities/player/player.tscn): `MainHandSocket`, `OffHandSocket`, `BackSocketWeapon`, `BackSocketShield`, `TeaBottleSocket`, `ItemPickupSocket`, além de `SlashEffect`.
   * Manter a mesma âncora base do sprite (`Vector2(-2, -29)` geral e `Vector2(-6.5, 4.0)` para `corner_climb`).
   * Manter a mesma regra de flip de instância (`_apply_visual_instance_flip`, preservando módulo da escala com fallback `0.8`), defaults de `pos`/`rot`/`z_index` por socket (incluindo `z_index = 2` em `corner_climb` quando `< 1`, e `z_index = 1` para `dagger` nas costas) e cálculo de `SlashEffect` (`base_pos + custom_offset`).
3. **Fachada Pública Intacta em `player.gd`:**
   * Manter em `Player` os métodos `_update_weapon_socket_for_frame(anim_name, frame_idx)`, `update_slash_frame_transform(frame_idx)`, `set_slash_visual(...)`, `equip_weapon(...)`, `equip_secondary_weapon(...)`, `equip_shield(...)` e `set_shield_raised(...)` como fachadas delegando para `PlayerEquipmentRig` e `PlayerCombatVFX`.

* **Critério de Teste (Fase 4):** Testar troca de armas (`1`/`2`), ataques terrestres/aéreos, *Slash VFX*, carga *Energize*, escudo/parry, cura (`Q`), coleta (`E`), morte com drop físico e validar explicitamente o [`weapon_socket_calibrator.tscn`](../src/tools/weapon_socket_calibrator.tscn) (troca de arma/escudo/animação/frame, preview de slash e salvamento no `.tres`).

---

### 🌐 FASE 5 — Conformidade Total de i18n (Regra 10) & Desacoplamento de Modais UI *(Concluída)*
* **O que foi feito:**
  1. Cadastradas em [`src/core/localization/translations.csv`](../src/core/localization/translations.csv) (com tradução contextual *humanlike* `pt_BR` e `en_US`) todas as strings que estavam hardcoded em:
     * `src/ui/hud.gd` (status de escudo, morte, repulsão e toast de Tier)
     * `src/entities/player/player.gd` (nomes de Tier)
     * `src/world/hub/weapon_pedestal.gd` (barks e avisos de pedestal)
     * `src/core/progression_manager.gd` (nomes de armas e metas de desbloqueio dos pedestais)
     * `src/ui/hub/mother_dialog_ui.gd` e `src/ui/hub/brother_forge_ui.gd` (labels de nível, dano e requisitos)
  2. Adicionados os modais (`MotherDialogUI`, `BrotherForgeUI`, `TouchOfDeathUI`, `DebugMetricsPanel`) ao grupo `"modal_ui"` e simplificado `PauseMenuUI._try_open_pause_menu()` para checar `_is_any_modal_open()` via grupo em vez de `find_child()` nominal.
* **Critério de Teste (Fase 5):** Testar HUD, pedestais da Casa Familiar, diálogos da Mãe/Irmão/Morte e Menu de Pausa sem nenhuma string hardcoded restante.

---

### 📜 FASE 6 — Guia Oficial de Criação de Scripts & Regra de Ouro em `REGRAS_DO_PROJETO.md`
* **O que será feito:**
  1. Criar o documento normativo [`docs/PADRAO_ARQUITETURAL_DE_SCRIPTS.md`](PADRAO_ARQUITETURAL_DE_SCRIPTS.md) especificando **exatamente como todo novo script deve ser criado daqui para frente**:
     * **Novos Inimigos:** Devem obrigatoriamente estender `BaseEnemy`, reutilizar `EnemyDeathState`, usar sensores do `BaseEnemy` (proibido criar nós `RayCast2D` soltos para borda/parede) e expor apenas estados específicos do seu arquétipo.
     * **Novas Armas / Golpes:** Devem ser 100% Data-Driven via `WeaponData` + `AttackSetData` + `ComboStepData` ([`docs/ARQUITETURA_ATTACK_SETS_E_SLASHES.md`](ARQUITETURA_ATTACK_SETS_E_SLASHES.md)), sem `if/else` de nome de arma em código.
     * **Novas Responsabilidades do Player:** Física/estados ficam em `src/entities/player/states/`; visuais de socket vão em `PlayerEquipmentRig`; efeitos de combate/partículas vão em `PlayerCombatVFX` (proibido inflar `player.gd`).
     * **Novas Telas / Modais de UI:** Devem pertencer ao grupo `"modal_ui"`, consumir 100% dos textos de `translations.csv` via `tr()` e usar `GamepadPromptBar`.
     * **Limite de Responsabilidade Única (SRP):** Scripts de entidade/controlador não devem ultrapassar ~350–400 linhas nem misturar física, UI e VFX no mesmo arquivo.
  2. Atualizar [`docs/REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md) incluindo [`docs/PADRAO_ARQUITETURAL_DE_SCRIPTS.md`](PADRAO_ARQUITETURAL_DE_SCRIPTS.md) na **Leitura Obrigatória do Topo** e como **Regra de Ouro Arquitetural** para qualquer novo código.
* **Critério de Teste (Fase 6):** Revisão da documentação pelo PO e validação headless final do repositório.
