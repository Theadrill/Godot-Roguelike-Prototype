# Padrão Arquitetural Oficial de Scripts — Severed Dawn

> [!IMPORTANT]
> Este documento é a **referência normativa obrigatória** (Regra 11 de [`REGRAS_DO_PROJETO.md`](REGRAS_DO_PROJETO.md)) para a criação ou refatoração de qualquer script (`.gd`) e cena (`.tscn`) no projeto **Severed Dawn**.
> Complementa [`ARQUITETURA_ATORES_E_BASE_ENEMY.md`](ARQUITETURA_ATORES_E_BASE_ENEMY.md) e [`ARQUITETURA_ATTACK_SETS_E_SLASHES.md`](ARQUITETURA_ATTACK_SETS_E_SLASHES.md).

---

## 1. Princípios Gerais, Orçamento de Linhas e Engenharia de Runtime

### 1.1. Responsabilidade Única (SRP) & Orçamento de Linhas por Categoria
É proibido misturar lógica física/FSM, sensores espaciais, gerenciamento de sockets, efeitos visuais (VFX/shaders), atalhos de debug e UI no mesmo script. Cada categoria possui um orçamento de linhas esperado:

| Categoria de Script | Exemplos | Teto Recomendado |
| :--- | :--- | :--- |
| **Estados individuais de FSM** | `patrol_state.gd`, `guard_state.gd`, `enemy_death_state.gd` | **~150–250 linhas** *(máx. ~350 para combos compostos)* |
| **Inimigos Concretos (`extends BaseEnemy`)** | [`soldier.gd`](../src/entities/enemies/melee/soldier/soldier.gd), [`archer.gd`](../src/entities/enemies/ranged/archer/archer.gd) | **~120–250 linhas** |
| **Sub-controladores modulares (`RefCounted`)** | `PlayerEquipmentRig`, `PlayerCombatVFX`, `PlayerSensors`, `PlayerDebugActions` | **~250–380 linhas** |
| **Classes-base e Orquestradores Centrais** | [`base_enemy.gd`](../src/entities/enemies/base_enemy.gd), [`family_house.gd`](../src/world/hub/family_house.gd), [`progression_manager.gd`](../src/core/progression_manager.gd) | **~400–550 linhas** |
| **Ator Principal (Fachada + Física Core)** | [`player.gd`](../src/entities/player/player.gd) | **~600–800 linhas** *(apenas core + fachadas delegadas)* |
| **Ferramentas Editor `@tool`** | [`weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd) | Sem teto fixo *(isolada em `src/tools/`, fora do runtime do jogo)* |

### 1.2. Engenharia de Runtime, Memória & Desacoplamento
1. **Imutabilidade de Recursos `.tres` em Runtime:**
   * Nunca modifique propriedades de um recurso `.tres` compartilhado em disco/cache (`WeaponData`, `ShieldData`, `AttackSetData`) diretamente durante a partida.
   * Sempre clone antes de aplicar bônus de run ou alternar modificadores em runtime (ex: `weapon_res.duplicate() as WeaponData`, como implementado em [`progression_manager.gd`](../src/core/progression_manager.gd), [`family_house.gd`](../src/world/hub/family_house.gd) e [`player_debug_actions.gd`](../src/entities/player/player_debug_actions.gd)).
2. **Padrão *Call Down, Signal Up* & Proibição de `find_child` por Frame:**
   * Nós pais chamam métodos em filhos via referências `@onready` cacheadas; filhos e sub-controladores comunicam eventos para cima via `signal` ou `ProgressionManager`.
   * É **proibido** chamar `find_child()`, `get_nodes_in_group()` ou `load()` dentro de `_process()` / `_physics_process()`. Cacheie referências no `_ready()` (ex.: `find_player()` com cache em `BaseEnemy`), use `StringName` (`&"..."`) em polling de `Input` e animações nos loops quentes, e aplique *throttling* nos sensores de percepção em patrulha via `should_run_patrol_scan(delta)`.
3. **Ciclo de Vida Seguro de `Tween` e Timers:**
   * Sempre armazene tweens recorrentes (flash, bark, fade, popup) em variável e chame `if tween and tween.is_valid(): tween.kill()` antes de criar outro, evitando competição de propriedades.
4. **Exposição Obrigatória de Métricas no Inspector (`@export`):**
   * Toda variável de balanceamento, *timing*, alcance, velocidade, janela defensiva ou duração deve ser exposta via `@export_group`, `@export_subgroup` e `@export_range` com sufixos de unidade (`"suffix:s"`, `"suffix:px"`, `"suffix:px/s"`) e docstrings `##`.
5. **Tipagem Forte e Zero Código Duplicado (DRY First):**
   * Use tipagem explícita (`var x: float = 0.0`, `func foo() -> void:`) e `class_name` nos scripts-base/componentes reutilizáveis.
   * Evite dependências cíclicas entre `class_name` (sub-controladores `RefCounted` usam `var _player: CharacterBody2D = null`).

---

## 2. Matriz Oficial de Physics Layers & Masks (`project.godot`)

Todo colisor de corpo, `Hitbox`, `Hurtbox` e `Area2D` deve respeitar estritamente esta matriz oficial definida em [`project.godot`](../project.godot):

| Bit | Valor (`2^(bit-1)`) | Nome Oficial | Quem Usa (`collision_layer`) | Quem Enxerga (`collision_mask`) |
| :---: | :---: | :--- | :--- | :--- |
| **1** | `1` | `Environment` | Chão, plataformas, paredes (`StaticBody2D`) | `Player`, `Enemies`, projéteis e raycasts `PhysicsRayQueryParameters2D(..., 1)` |
| **2** | `2` | `Player` | Corpo físico de [`player.tscn`](../src/entities/player/player.tscn) (`CharacterBody2D`) | `Area2D` de interação/detecção (`WeaponPedestal`, `InteractableArea`, zonas de portal) |
| **3** | `4` | `Enemies` | Corpo físico dos inimigos (`BaseEnemy` `CharacterBody2D`) | `Player/EnemyOverlapDetector` (`collision_mask = 4`) |
| **4** | `8` | `PlayerHitbox` | `Player/Visual/Hitbox` (`Hitbox`) | Máscara `64` (`EnemyHurtbox`) |
| **5** | `16` | `EnemyHitbox` | `Hitbox` de inimigos e projéteis inimigos | Máscara `32` (`PlayerHurtbox`) |
| **6** | `32` | `PlayerHurtbox` | `Player/Hurtbox` (`Hurtbox`) | `0` (passivo, recebido pelas hitboxes inimigas) |
| **7** | `64` | `EnemyHurtbox` | `Hurtbox` dos inimigos (`BaseEnemy`) | `0` (passivo, recebido pela hitbox do player) |

---

## 3. Padrão para Novos Inimigos (`src/entities/enemies/`)

### 3.1. Blueprint Canônico da Árvore de Nós (`.tscn`)
Todo novo inimigo terrestre deve seguir esta estrutura mínima obrigatória (para que o `@onready` de `BaseEnemy` resolva sem falhas silenciosas):

```text
NovoInimigo (CharacterBody2D) [script: extends BaseEnemy, collision_layer = 4, floor_snap_length = 8.0]
├── CollisionShape2D            # Caixa física centrada em (0, -20), ex: 16×40 (Pivô nos pés)
├── Visual (Node2D)             # Escala X controla a direção; magnitude controla Elite (1.15x)
│   ├── Body (Polygon2D / Sprite2D)
│   ├── TelegraphMark (Node2D)  # Posicionado acima da cabeça, ex: (0, -48)
│   │   ├── WhiteMark           # Sinal Branco (Normal)
│   │   ├── YellowMark          # Sinal Amarelo (Heavy)
│   │   └── RedMark             # Sinal Vermelho (Perilous)
│   └── Hitbox (Area2D)         # (Se melee) Script hitbox.gd, layer = 16, mask = 32
├── Hurtbox (Area2D)            # Script hurtbox.gd, layer = 64, mask = 0
│   └── CollisionShape2D
└── StateMachine (Node)         # Script state_machine.gd
    ├── Patrol (Node)           # Estado específico de patrulha
    ├── ...                     # Estados de combate/movimento do arquétipo
    ├── Hurt (Node)             # Estado de stagger/hit
    └── Death (Node)            # OBRIGATORIAMENTE: src/entities/enemies/states/enemy_death_state.gd
```

### 3.2. Regras de Implementação em Código
1. **Herança Obrigatória de `BaseEnemy`:**
   * O script raiz **DEVE** estender `BaseEnemy` ([`src/entities/enemies/base_enemy.gd`](../src/entities/enemies/base_enemy.gd)).
   * Utilize os *virtual hooks* de `BaseEnemy` sem duplicar Tiers, Elite, `update_facing()`, `hit_flash`, `respawn()` ou `apply_parry_stun()`:
     * `_on_enemy_ready()`, `_on_enemy_physics_process(delta)`
     * `_on_hit_received(amount, knockback, hitstop)`
     * `_on_parry_stun_applied(duration)`
     * `_on_death_enter()`, `_on_enemy_respawn()`
     * `_get_flash_target()`, `_get_tier_body_color()`
2. **Proibição de Nós `RayCast2D` Manuais:**
   * **PROIBIDO** adicionar nós `RayCast2D` soltos (`WallCheck`, `LedgeCheck`, `SightRay`) em `.tscn` de inimigos.
   * Use exclusivamente os sensores *stateless* (`PhysicsRayQueryParameters2D`, Layer 1) de `BaseEnemy`: `can_step_forward()`, `can_step_backward()`, `can_step_in_direction()`, `is_at_ledge()`, `is_hitting_wall()`, `has_line_of_sight_to()`, `find_player()`.
3. **Morte Compartilhada & Telegraphs:**
   * `StateMachine/Death` usa [`EnemyDeathState`](../src/entities/enemies/states/enemy_death_state.gd). Não crie scripts `death_state.gd` por inimigo.
   * Use `advance_attack_cycle()` e `show_telegraph(current_attack_type)` / `hide_telegraph()`. Multiplicadores de telegraph ficam em `BaseEnemy`; janelas de *parry* e *whiff* ficam no `Player` / `ShieldData`.

---

## 4. Padrão para Armas, Escudos e Golpes (`src/combat/` & `src/entities/equipment/`)

1. **Arquitetura 100% Data-Driven (Resources `.tres`):**
   * Novas armas e golpes combinam `WeaponData` ([`src/combat/weapon_data.gd`](../src/combat/weapon_data.gd)) + `AttackSetData` (`res://src/combat/sets/`) + `ComboStepData` conforme [`ARQUITETURA_ATTACK_SETS_E_SLASHES.md`](ARQUITETURA_ATTACK_SETS_E_SLASHES.md).
   * Novos escudos usam [`ShieldData`](../src/combat/shield_data.gd).
2. **Proibição de Condicionais por Nome ou Caminho em Código:**
   * Nunca faça `if "nome" in weapon.resource_path` dentro de lógica de gameplay. Use `weapon.weapon_category`, `weapon.get_archetype_id()` e `weapon.get_socket_profile()`.
3. **Sorteio Dinâmico no Hub (`FamilyHouse`):**
   * Armas elegíveis entram em `melee_weapon_pool` ou `ranged_weapon_pool` em [`family_house.gd`](../src/world/hub/family_house.gd) e são clonadas via `.duplicate()` em runtime.
   * Regra de sorteio: `1` pedestal de arma desbloqueado = `1` arma aleatória; `>= 2` pedestais desbloqueados = garantia de pelo menos `1` Melee e `1` Ranged sem repetições.

---

## 5. Padrão para o `Player` e Paridade com `WeaponSocketCalibrator`

1. **Sub-controladores Modulares (`src/entities/player/`):**
   * [`player.gd`](../src/entities/player/player.gd) + `src/entities/player/states/`: atributos, física base, timers, saúde/*Rally*, sinais e fachada pública da FSM.
   * [`PlayerEquipmentRig`](../src/entities/player/player_equipment_rig.gd): ancoragem nos 6 sockets, flip de instância, visibilidade no hub e drop físico na morte.
   * [`PlayerCombatVFX`](../src/entities/player/player_combat_vfx.gd): *SlashEffect*, *Energize* shader/partículas, impacto de chão e *Pickup Burst*.
   * [`PlayerSensors`](../src/entities/player/player_sensors.gd): `check_ledge()` (mantle 4 estágios), `is_pushing_against_enemy()` e filtros de intenção analógica (`is_crouch_requested`, `is_upward_attack_requested`, `is_ground_slam_requested`).
   * [`PlayerDebugActions`](../src/entities/player/player_debug_actions.gd): atalhos de debug em runtime restritos a `OS.is_debug_build()` (`T`, `Y`, `cycle_reserve_weapon`, `toggle_shield_repulsion`).
2. **Contrato de Invariância com o `WeaponSocketCalibrator`:**
   * Preservar **paridade matemática 1:1** com [`weapon_socket_calibrator.gd`](../src/tools/weapon_socket_calibrator.gd):
     * Manter os 6 nós sob `Visual` em [`player.tscn`](../src/entities/player/player.tscn) (`MainHandSocket`, `OffHandSocket`, `BackSocketWeapon`, `BackSocketShield`, `TeaBottleSocket`, `ItemPickupSocket`) + `SlashEffect`.
     * Manter as âncoras-base (`Vector2(-2, -29)` geral e `Vector2(-6.5, 4.0)` em `corner_climb`), lógica de flip e defaults de `z_index`.
     * Manter as fachadas delegadas em `player.gd` e validar no [`weapon_socket_calibrator.tscn`](../src/tools/weapon_socket_calibrator.tscn) após mudanças nessa camada.

---

## 6. Padrão para Mundo, Interações & Cenas (`src/world/`)

1. **Componente Único de Interação (`InteractableArea`):**
   * Novos objetos/NPCs interativos **DEVEM** usar [`InteractableArea`](../src/world/components/interactable_area.gd) diretamente como nó filho ou conectar `Area2D` existente via `InteractableArea.bind_area(...)`, evitando reescrever `body_entered`, `body_exited` e `input_event`.
   * *Exceção documentada:* grupos que exigem foco exclusivo entre adjacentes (ex: [`WeaponPedestal`](../src/world/hub/weapon_pedestal.gd)) ou coleta com respawn customizado ([`PickupItem`](../src/world/items/pickup_item.gd)) mantêm seleção própria por distância, podendo delegar gatilhos auxiliares quando aplicável.
2. **Agrupamento de Geometria (`StaticBody2D` / `_Col` -> `_Vis`):**
   * Em cenas de fase, hub ou *gym* (ex: [`movement_gym.tscn`](../src/world/movement_gym.tscn)), todo visual (`Polygon2D` / `Sprite2D` `_Vis`) pertence como **filho direto** do respectivo `CollisionShape2D` (`_Col`) com posição local `(0, 0)`.

---

## 7. Padrão para UI, Modais e Localização (i18n)

1. **Blueprint Canônico de Modal UI & Desacoplamento (`"modal_ui"`):**
   * Toda tela modal sobreposta (`CanvasLayer` / diálogo / loja / inventário / debug) **DEVE**:
     * Definir `process_mode = Node.PROCESS_MODE_ALWAYS` (quando operando sob pausa).
     * Chamar `add_to_group("modal_ui")` no `_ready()`.
     * Incluir `GamepadPromptBar` e chamar `grab_focus()` no botão principal ao abrir (`open_ui()`).
   * [`PauseMenuUI`](../src/ui/pause/pause_menu_ui.gd) consulta exclusivamente o grupo `"modal_ui"` via `_is_any_modal_open()` — proibido adicionar `find_child()` nominal para novos modais.
2. **Auto-Scroll em Listas Focáveis:**
   * Todo `ScrollContainer` com lista de botões navegáveis por teclado/gamepad deve usar `follow_focus = true` na cena `.tscn` e conectar `focus_entered` dos controles filhos a `scroll.ensure_control_visible(ctrl)` (padrão [`debug_metrics_panel.gd`](../src/ui/debug/debug_metrics_panel.gd)).
3. **Conformidade Total de i18n (Regra 10) vs. Ferramentas Internas DEV:**
   * **Obrigatório (`100% translations.csv`):** Toda string visível ao jogador (HUD, menus, pause, diálogos, pedestais, barks, itens, mensagens de progresso) deve residir em [`translations.csv`](../src/core/localization/translations.csv) com tradução contextual *humanlike* (`pt_BR` e `en_US`) via `tr()` / `LocalizationService`.
   * **Escopo de Ferramentas Internas (`DEV / @tool`):** Overlays técnicos e painéis exclusivos de debug/calibração (como [`PerformanceOverlay`](../src/ui/debug/performance_overlay.gd), [`DebugMetricsPanel`](../src/ui/debug/debug_metrics_panel.gd) e [`WeaponSocketCalibrator`](../src/tools/weapon_socket_calibrator.gd)) têm foco estritamente interno ao time de desenvolvimento e não exigem localização comercial, embora possam usar chaves quando compartilharem strings do jogo.

---

## 8. Checklist Rápido Antes de Entregar Qualquer Novo Script

- [ ] **Inimigo novo?** Segue o Blueprint da Seção 3.1, estende `BaseEnemy`, usa sensores de `BaseEnemy` (sem `RayCast2D` na `.tscn`) e usa `EnemyDeathState`.
- [ ] **Arma/Golpe novo?** Usa `WeaponData` + `AttackSetData` + `ComboStepData`, e o runtime usa `.duplicate()` antes de mutar qualquer dado.
- [ ] **Alterou sockets/slash do Player?** Manteve paridade 1:1 com `WeaponSocketCalibrator` e validou o calibrador.
- [ ] **Nova interação de mundo?** Usa `InteractableArea` / `InteractableArea.bind_area(...)`.
- [ ] **UI/Modal novo?** Adicionado ao grupo `"modal_ui"`, `ScrollContainer` com `follow_focus = true`, `GamepadPromptBar` e `100%` das strings do jogador em `translations.csv` (`humanlike`).
- [ ] **Tuning exposto e Layers corretas?** Métricas via `@export_group`/`@export_range` e bits conforme Tabela da Seção 2.
- [ ] **Validado no CLI?** Executado `C:\Tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --editor --quit --path . 2>&1` com saída limpa (`0` erros).
