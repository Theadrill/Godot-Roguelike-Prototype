# Padrão Arquitetural Oficial de Scripts — Severed Dawn

> [!IMPORTANT]
> Este documento é a **referência normativa obrigatória** (Regra 11 de [`REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md)) para a criação ou refatoração de qualquer script (`.gd`) e cena (`.tscn`) no projeto **Severed Dawn**.
> Complementa [`ARQUITETURA_ATORES_E_BASE_ENEMY.md`](ARQUITETURA_ATORES_E_BASE_ENEMY.md) e [`ARQUITETURA_ATTACK_SETS_E_SLASHES.md`](ARQUITETURA_ATTACK_SETS_E_SLASHES.md).

---

## 1. Princípios Gerais (SRP, Tamanho e Customização no Inspector)

1. **Responsabilidade Única (SRP) e Limite de Tamanho:**
   * Scripts de entidade/controlador (`Player`, inimigos, UIs, cenas do mundo) devem permanecer enxutos (**~350–400 linhas no máximo**) e com foco único.
   * É proibido misturar lógica física/FSM, gerenciamento de sockets, efeitos visuais (VFX/partículas/shaders) e interface (UI) no mesmo script.
   * Comportamentos reutilizáveis devem viver em sub-controladores dedicados (`RefCounted` / componentes) ou nós compartilhados (ex: `Hitbox`, `Hurtbox`, `StateMachine`).

2. **Exposição Obrigatória de Métricas no Inspector (`@export`):**
   * Toda variável de balanceamento, *timing*, alcance, velocidade, janela defensiva ou duração deve ser exposta via `@export_group`, `@export_subgroup` e `@export_range` com sufixos de unidade (`"suffix:s"`, `"suffix:px"`, `"suffix:px/s"`) e comentário de doc `##` para o PO poder ajustar diretamente no Inspector da Godot.
   * Nunca esconda valores mágicos críticos dentro de funções de estado.

3. **Tipagem Forte e Zero Código Duplicado (DRY First):**
   * Use tipagem explícita (`var x: float = 0.0`, `func foo() -> void:`) e `class_name` nos scripts-base/componentes reutilizáveis.
   * Nunca duplique funções utilitárias entre estados ou atores; promova helpers comuns para a classe-base (`BaseEnemy`, `Player`, etc.).

---

## 2. Padrão para Novos Inimigos (`src/entities/enemies/`)

Todo novo inimigo terrestre deve seguir exatamente esta estrutura:

1. **Herança Obrigatória de `BaseEnemy`:**
   * O script raiz do inimigo (`CharacterBody2D`) **DEVE** estender `BaseEnemy` ([`src/entities/enemies/base_enemy.gd`](../src/entities/enemies/base_enemy.gd)):
     ```gdscript
     class_name NovoInimigo
     extends BaseEnemy
     ```
   * Não reimplemente Tiers (`apply_tier_by_level`), escala Elite (`1.15x`), `update_facing()`, `hit_flash`, `show_telegraph()` / `hide_telegraph()`, `advance_attack_cycle()`, `apply_parry_stun()` ou `respawn()`. Utilize os métodos e *virtual hooks* de `BaseEnemy`:
     * `_on_enemy_ready()`
     * `_on_enemy_physics_process(delta)`
     * `_on_hit_received(amount, knockback, hitstop)`
     * `_on_parry_stun_applied(duration)`
     * `_on_death_enter()`
     * `_on_enemy_respawn()`
     * `_get_flash_target()` / `_get_tier_body_color()`

2. **Proibição de Nós `RayCast2D` Manuais para Borda/Parede/Visão:**
   * **PROIBIDO** adicionar nós `RayCast2D` soltos (`WallCheck`, `LedgeCheck`, `SightRay`, etc.) nas cenas `.tscn` de inimigos para navegação de plataforma ou linha de visão.
   * Utilize exclusivamente os sensores espaciais *stateless* (`PhysicsRayQueryParameters2D`, Layer 1) já fornecidos por `BaseEnemy`:
     * `can_step_forward(edge_offset)` / `can_step_backward(edge_offset)` / `can_step_in_direction(dir, edge_offset)`
     * `is_at_ledge(dir, edge_offset)` / `is_hitting_wall(dir, wall_dist)`
     * `has_line_of_sight_to(target)` / `find_player()`

3. **Morte Compartilhada & Estados Específicos:**
   * O nó `StateMachine/Death` da cena do inimigo **DEVE** usar o script compartilhado [`EnemyDeathState`](../src/entities/enemies/states/enemy_death_state.gd) (`src/entities/enemies/states/enemy_death_state.gd`). Não crie novos scripts `death_state.gd` por inimigo.
   * Mantenha na pasta `states/` do inimigo apenas os estados específicos do seu arquétipo (ex: `Patrol`, `Chase`/`Kite`, `Attack`/`Shoot`, `Hurt`).

4. **Sistema de 3 Sinais (Telegraphs):**
   * Use `advance_attack_cycle()` e `show_telegraph(current_attack_type)` / `hide_telegraph()` de `BaseEnemy`.
   * Os multiplicadores de duração de telegraph (`normal_telegraph_mult`, `heavy_telegraph_mult`, `perilous_telegraph_mult`) vêm de `BaseEnemy`; as janelas de *parry* e *whiff* pertencem exclusivamente ao `Player` / `ShieldData`.

---

## 3. Padrão para Armas, Escudos e Golpes (`src/combat/` & `src/entities/equipment/`)

1. **Arquitetura 100% Data-Driven (Resources `.tres`):**
   * Novas armas e golpes devem ser criados como recursos `.tres` combinando `WeaponData` ([`src/combat/weapon_data.gd`](../src/combat/weapon_data.gd)) + `AttackSetData` (`res://src/combat/sets/`) + `ComboStepData`, conforme detalhado em [`ARQUITETURA_ATTACK_SETS_E_SLASHES.md`](ARQUITETURA_ATTACK_SETS_E_SLASHES.md).
   * Novos escudos utilizam [`ShieldData`](../src/combat/shield_data.gd).

2. **Proibição de Condicionais por Nome ou Caminho em Código:**
   * Nunca faça `if "nome_da_arma" in weapon.resource_path` dentro de estados de combate ou VFX.
   * Use as propriedades tipadas de `WeaponData`: `weapon.weapon_category` (`MELEE`, `RANGED_BOW`, `RANGED_CROSSBOW`, `RANGED_SPELL`), `weapon.get_archetype_id()` e `weapon.get_socket_profile()`.

3. **Sorteio Dinâmico no Hub (`FamilyHouse`):**
   * Armas elegíveis na cabana são registradas nos pools exportados em [`family_house.gd`](../src/world/hub/family_house.gd) (`melee_weapon_pool`, `ranged_weapon_pool`, `shield_pool`) usando `.duplicate()` em runtime para não mutar os `.tres` originais.
   * Pedestais desbloqueados seguem a regra: `1` pedestal aberto = `1` arma aleatória; `>= 2` pedestais abertos = garantia de pelo menos `1` Melee e `1` Ranged sem repetições.

---

## 4. Padrão para o `Player` e Paridade com `WeaponSocketCalibrator`

1. **Separação Estrita de Sub-controladores (`src/entities/player/`):**
   * **Física, inputs, saúde, *Rally* e fachada da FSM:** [`player.gd`](../src/entities/player/player.gd) + estados individuais em `src/entities/player/states/`.
   * **Sockets de mão/costas, instância visual e drop físico na morte:** [`PlayerEquipmentRig`](../src/entities/player/player_equipment_rig.gd).
   * **Efeitos visuais de combate (`SlashEffect`, *Energize*, impacto no chão, *Pickup Burst*):** [`PlayerCombatVFX`](../src/entities/player/player_combat_vfx.gd).
   * É **proibido** reinflar `player.gd` com manipulação direta de transformações frame a frame de sockets ou tweens de VFX; novas features visuais devem ir para `PlayerEquipmentRig` ou `PlayerCombatVFX`.

2. **Contrato de Invariância com o `WeaponSocketCalibrator`:**
   * Qualquer alteração em `PlayerEquipmentRig`, `PlayerCombatVFX`, `WeaponSocketProfile` ou [`player.tscn`](../src/entities/player/player.tscn) deve preservar **paridade matemática 1:1** com [`weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd):
     * Os 6 nós de socket sob `Visual` em `player.tscn` (`MainHandSocket`, `OffHandSocket`, `BackSocketWeapon`, `BackSocketShield`, `TeaBottleSocket`, `ItemPickupSocket`) + `SlashEffect` devem manter nomes e hierarquia intactos.
     * Manter as mesmas âncoras-base (`Vector2(-2, -29)` geral e `Vector2(-6.5, 4.0)` em `corner_climb`), lógica de flip e defaults de `z_index`.
     * Manter em `player.gd` as fachadas públicas delegadas (`_update_weapon_socket_for_frame`, `update_slash_frame_transform`, `set_slash_visual`, `equip_weapon`, `equip_secondary_weapon`, `equip_shield`, `set_shield_raised`).
   * Sempre validar no [`weapon_socket_calibrator.tscn`](../src/tools/weapon_socket_calibrator.tscn) após alterar qualquer coisa nessa camada.

---

## 5. Padrão para UI, Modais e Localização (i18n)

1. **Desacoplamento de Janelas Modais via Grupo `"modal_ui"`:**
   * Toda tela modal sobreposta (`CanvasLayer` / painel de diálogo / loja / inventário / debug) **DEVE** chamar `add_to_group("modal_ui")` no `_ready()` e definir `process_mode = Node.PROCESS_MODE_ALWAYS` quando precisar responder com o jogo pausado.
   * [`PauseMenuUI`](../src/ui/pause/pause_menu_ui.gd) consulta automaticamente o grupo `"modal_ui"` em `_is_any_modal_open()` — é **proibido** adicionar `find_child("NomeDoModal")` nominal no menu de pausa.

2. **Navegação por Foco e Acessibilidade a Gamepad (`GamepadPromptBar`):**
   * Listas de botões dentro de `ScrollContainer` devem ter `follow_focus = true` na cena `.tscn` e chamar `scroll.ensure_control_visible(ctrl)` no sinal `focus_entered` dos botões filhos (ex: [`debug_metrics_panel.gd`](../src/ui/debug/debug_metrics_panel.gd)).
   * Sempre incluir `GamepadPromptBar` e garantir `grab_focus()` ao abrir o modal em teclado/gamepad.

3. **Conformidade Total de i18n (Regra 10):**
   * **Zero strings literais** visíveis ao jogador em `.gd` ou `.tscn`.
   * Todo texto entra em [`res://src/core/localization/translations.csv`](../src/core/localization/translations.csv) usando os prefixos oficiais (`UI_*`, `BARK_*`, `ITEM_*`, `LORE_*`, `MSG_*`) e consumido via `tr("CHAVE")` (ou `LocalizationService` para barks aleatórios).
   * Traduções em `pt_BR` e `en_US` devem ser **contextuais e humanlike** (*Dark Fantasy Rústica*), nunca literais estilo tradutor automático.

---

## 6. Organização de Cenas de Mundo (`StaticBody2D` / Colisores)

* Em cenas de mapa, hub ou *gym* (ex: [`movement_gym.tscn`](../src/world/movement_gym.tscn)), todo nó visual (`Polygon2D` / `Sprite2D` `_Vis`) de uma plataforma, bloco ou parede pertence como **filho direto** do seu respectivo `CollisionShape2D` (`_Col`) com posição local `(0, 0)` relativa ao colisor.
* Assim, mover ou ajustar geometria de colisão no editor move automaticamente a arte correspondente junto, evitando dessincronia física vs. visual.

---

## 7. Checklist Rápido Antes de Entregar Qualquer Novo Script

- [ ] **Inimigo novo?** Herda `BaseEnemy`, usa sensores de `BaseEnemy` (sem `RayCast2D` extra na `.tscn`) e usa `EnemyDeathState`.
- [ ] **Arma/Golpe novo?** Usa `WeaponData` + `AttackSetData` + `ComboStepData` sem `if/else` de nome em código.
- [ ] **Alterou sockets/slash do Player?** Manteve paridade 1:1 com `WeaponSocketCalibrator` e validou o calibrador.
- [ ] **UI/Modal novo?** Adicionado ao grupo `"modal_ui"`, `ScrollContainer` com `follow_focus = true` + `ensure_control_visible()`, e `100%` das strings em `translations.csv` (`humanlike`).
- [ ] **Tuning exposto?** Parâmetros críticos no Inspector via `@export_group` / `@export_range` + `##`.
- [ ] **Validado no CLI?** Executado `C:\Tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --editor --quit --path . 2>&1` com saída limpa (`0` erros).
