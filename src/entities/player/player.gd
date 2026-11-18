class_name Player
extends CharacterBody2D

## Player controller implementing the physics metrics and state management.

signal flask_charges_changed(current: int, max_charges: int)

@export_group("Health Flask (Mother's Tea)")
@export var max_flask_charges: int = 1
@export_range(0.1, 1.0, 0.05) var flask_heal_percent: float = 0.40
@export_range(0.1, 2.0, 0.05, "suffix:s") var flask_channel_duration: float = 0.55
var current_flask_charges: int = 1
var _bark_tween: Tween = null

@export_group("Attributes & Stats")
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_health: float = 200.0
@export_range(0.0, 500.0, 1.0, "or_greater") var max_mana: float = 100.0
var current_health: float = 200.0
var current_mana: float = 100.0

@export_group("Debug")
@export var debug_start_at_90_health: bool = false
@export var debug_infinite_heal: bool = false

@export_group("Tactical Life Rally")
const RALLY_DURATION: float = 2.0
var rally_recoverable_hp: float = 0.0
var rally_timer: float = 0.0

@export_group("Horizontal Movement")
@export_range(50.0, 600.0, 10.0, "suffix:px/s") var run_speed: float = 220.0
@export_range(0.01, 0.5, 0.01, "suffix:s") var acceleration_time: float = 0.08

@export_group("Jumping & Gravity")
@export_range(-800.0, -100.0, 10.0, "suffix:px/s") var jump_velocity: float = -354.0        # Exact 4 tiles (64 px)
@export_range(-800.0, -100.0, 10.0, "suffix:px/s") var double_jump_velocity: float = -306.0 # Exact +3 tiles (48 px)
@export_range(0.5, 3.0, 0.05) var fall_gravity_multiplier: float = 1.35                     # Snappy fall (Dead Cells)
@export_range(0.0, 0.3, 0.01, "suffix:s") var coyote_duration: float = 0.12
@export_range(0.0, 0.3, 0.01, "suffix:s") var jump_buffer_duration: float = 0.12
@export_range(0.0, 0.3, 0.01, "suffix:s") var attack_buffer_duration: float = 0.15
@export_range(100.0, 600.0, 10.0, "suffix:px") var hard_landing_min_distance: float = 180.0
@export_range(0.05, 0.5, 0.01, "suffix:s") var hard_landing_duration: float = 0.18

@export_group("Wall Mechanics")
@export_range(5.0, 100.0, 5.0, "suffix:px/s") var wall_slide_min_speed: float = 15.0
@export_range(50.0, 500.0, 10.0, "suffix:px/s") var wall_slide_max_speed: float = 220.0
@export_range(0.0, 3.0, 0.1, "suffix:s") var wall_cling_hold_time: float = 0.5
@export_range(0.2, 4.0, 0.1, "suffix:s") var wall_slide_accel_duration: float = 1.2
@export_range(0.5, 6.0, 0.1, "suffix:s") var wall_grip_duration: float = 2.2
@export_range(16.0, 200.0, 4.0, "suffix:px") var wall_regrab_min_fall_distance: float = 48.0
@export_range(0.5, 1.0, 0.05) var wall_recovery_gravity_multiplier: float = 0.85
@export_range(50.0, 500.0, 10.0, "suffix:px/s") var wall_jump_horizontal: float = 240.0
@export_range(0.1, 0.8, 0.05) var wall_jump_inward_ratio: float = 0.38
@export_range(-600.0, -100.0, 10.0, "suffix:px/s") var wall_jump_vertical: float = -330.0

@export_group("Slide & Dodge")
@export_range(100.0, 800.0, 10.0, "suffix:px/s") var slide_speed: float = 240.0
@export_range(0.1, 1.0, 0.01, "suffix:s") var slide_duration: float = 0.28

## Compatibilidade retroativa com roll
var roll_speed: float:
	get: return slide_speed
	set(val): slide_speed = val
var roll_duration: float:
	get: return slide_duration
	set(val): slide_duration = val

@export_group("Combat & Equipment")
@export var weapon: WeaponData
@export var secondary_weapon: WeaponData
@export var shield: ShieldData

@export_group("Shield & Parry Tuning")
## Janela base de Parry Perfeito em segundos (se > 0.0, sobrescreve o valor do recurso ShieldData).
@export_range(0.0, 1.5, 0.02, "suffix:s") var parry_window_override: float = 0.24
## Bônus extra de janela de Parry especificamente contra ataques Vermelhos (PERILOUS).
@export_range(0.0, 1.0, 0.02, "suffix:s") var perilous_parry_extra_window: float = 0.10
## Cooldown de penalidade ao errar um clique seco de Parry (-1.0 usa o do escudo; 0.0 desativa a penalidade).
@export_range(-1.0, 3.0, 0.05, "suffix:s") var parry_fail_cooldown_override: float = -1.0
## Se false (padrão), soltar a guarda após segurar o escudo NÃO aplica penalidade de whiff (permite soltar e re-apertar para dar Parry no ataque vermelho!).
@export var punish_guard_release_after_hold: bool = false
## Tempo de escudo bloqueado quando um ataque Vermelho quebra a guarda contínua.
@export_range(0.1, 3.0, 0.05, "suffix:s") var guard_break_cooldown: float = 1.5
## Duração do stagger quando a guarda é quebrada por ataque Vermelho.
@export_range(0.1, 2.0, 0.05, "suffix:s") var guard_break_stagger_duration: float = 0.55

@export_group("Socket Profiles")
## Perfil global de ancoragem do tronco/costas (BackSocketWeapon e BackSocketShield).
@export var back_socket_profile: BackSocketProfile

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var attack_buffer_timer: float = 0.0
var can_double_jump: bool = false
var facing_direction: int = 1

# Wall jump tracking: prevents infinite climbing on the same single wall
var last_wall_jump_normal_x: float = 0.0
var wall_fall_start_y: float = 0.0
var is_wall_recovery_active: bool = false
var fall_peak_y: float = 0.0

# Soft body collision: movement resistance when pushing through enemies (Dead Cells style)
@export_range(0.05, 0.9, 0.05) var enemy_overlap_speed_multiplier: float = 0.28

@export_group("Input Tolerance")
## Deadzone threshold for analog vertical actions (crouch and upward attack).
## 0.55 (55%) prevents accidental crouches and up-attacks while moving left/right.
@export_range(0.3, 0.85, 0.05) var vertical_input_threshold: float = 0.55

# Default gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial
@export_range(0.0, 2.0, 0.05, "suffix:s") var post_hit_invuln_duration: float = 0.45
@export_range(0.0, 0.5, 0.01, "suffix:s") var hurt_flinch_duration: float = 0.14
var post_hit_invuln_timer: float = 0.0
var hurt_flinch_timer: float = 0.0
var _pending_anim_after_flinch: StringName = &""
var is_dodge_invulnerable: bool = false
var attack_cooldown_timer: float = 0.0
var parry_cooldown_timer: float = 0.0
var ledge_target_position: Vector2 = Vector2.ZERO

## Trava total de inputs e controles (usado durante menus, diálogos diegéticos e transições)
var _ignore_roll_timer: float = 0.0
var is_input_locked: bool = false:
	set(value):
		var was_locked: bool = is_input_locked
		is_input_locked = value
		if is_input_locked:
			jump_buffer_timer = 0.0
			velocity.x = 0.0
			if state_machine:
				state_machine.transition_to("idle")
		elif was_locked:
			# Evita que o botão B usado para fechar janelas acione roll/dodge indesejado
			_ignore_roll_timer = 0.35
			jump_buffer_timer = 0.0

func is_slide_requested() -> bool:
	return _ignore_roll_timer <= 0.0 and not is_input_locked and (
		Input.is_action_just_pressed("slide") or Input.is_action_just_pressed("roll")
	)

func is_roll_requested() -> bool:
	return is_slide_requested()

@onready var state_machine: StateMachine = $StateMachine
const default_slash_frames = preload("res://assets/effects/slashes/slash_frames.tres")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/BodyPlaceholder
@onready var player_sprite: AnimatedSprite2D = $Visual.get_node_or_null("PlayerSprite") as AnimatedSprite2D
@onready var idle_sprite: AnimatedSprite2D = player_sprite
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var enemy_overlap_detector: Area2D = $EnemyOverlapDetector
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var slash_effect: AnimatedSprite2D = $Visual.get_node_or_null("SlashEffect") as AnimatedSprite2D
@onready var ledge_climb_visual: Node2D = $Visual/LedgeClimbPlaceholder
@onready var main_hand_socket: Marker2D = $Visual/MainHandSocket
@onready var off_hand_socket: Marker2D = $Visual/OffHandSocket
@onready var back_socket_shield: Marker2D = $Visual/BackSocketShield
@onready var back_socket_weapon: Marker2D = $Visual/BackSocketWeapon
@onready var tea_bottle_socket: Marker2D = $Visual.get_node_or_null("TeaBottleSocket") as Marker2D
@onready var item_pickup_socket: Marker2D = $Visual.get_node_or_null("ItemPickupSocket") as Marker2D
@onready var bark_label: Label = get_node_or_null("BarkLabel") as Label
@onready var death_screen: DeathScreen = get_node_or_null("DeathScreen") as DeathScreen
@onready var low_health_vignette: LowHealthVignette = get_node_or_null("LowHealthVignette") as LowHealthVignette

var equipment_rig: PlayerEquipmentRig = PlayerEquipmentRig.new()
var combat_vfx: PlayerCombatVFX = PlayerCombatVFX.new()

var _main_weapon_instance: Node2D = null
var _secondary_weapon_instance: Node2D = null
var _shield_instance: Node2D = null
var _tea_bottle_instance: Node2D = null
var _item_pickup_instance: Node2D = null
var _dropped_death_items: Array[Node] = []
var tea_bottle_frame_override: int = -1
var is_shield_raised: bool = false
var is_dead: bool = false
var are_weapons_hidden: bool = false
var _spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
	current_health = max_health
	current_mana = max_mana
	current_flask_charges = max_flask_charges
	flask_charges_changed.emit(current_flask_charges, max_flask_charges)
	
	if death_screen:
		death_screen.respawn_requested.connect(_on_death_respawn)
		death_screen.main_menu_requested.connect(_on_death_main_menu)
	if not weapon:
		var default_weapon := load("res://src/entities/equipment/swords/weapon_sword_base.tres") as WeaponData
		weapon = default_weapon if default_weapon else WeaponData.new()

	if not secondary_weapon:
		var default_secondary := load("res://src/entities/equipment/bows/weapon_bow_base.tres") as WeaponData
		if default_secondary:
			secondary_weapon = default_secondary

	if not shield:
		var default_shield := load("res://src/entities/equipment/shields/shield_buckler_base.tres") as ShieldData
		if default_shield:
			shield = default_shield

	if not back_socket_profile:
		var default_back := load("res://src/entities/equipment/socket_profiles/back_socket.tres") as BackSocketProfile
		if default_back:
			back_socket_profile = default_back

	equipment_rig.setup(self)
	combat_vfx.setup(self)

	if player_sprite:
		player_sprite.animation_finished.connect(_on_player_sprite_animation_finished)
		player_sprite.frame_changed.connect(_on_player_sprite_frame_changed)

	_refresh_equipped_visuals()
	_update_equipment_depth()
	ProgressionManager.apply_to_player(self)
	if debug_start_at_90_health:
		current_health = max_health * 0.9

	if hitbox:
		hitbox.attacker = self

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	# Setup hit flash shader material
	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	if shader and body_polygon:
		flash_material = ShaderMaterial.new()
		flash_material.shader = shader
		body_polygon.material = flash_material

	if slash_effect and slash_effect is AnimatedSprite2D:
		slash_effect.animation_finished.connect(func(): slash_effect.visible = false)
		slash_effect.frame_changed.connect(_on_slash_effect_frame_changed)

func equip_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	equipment_rig.update_main_weapon_visual()

func equip_secondary_weapon(new_secondary: WeaponData) -> void:
	secondary_weapon = new_secondary
	equipment_rig.update_secondary_weapon_visual()

func equip_shield(new_shield: ShieldData) -> void:
	shield = new_shield
	equipment_rig.update_shield_visual()

func set_shield_raised(raised: bool) -> void:
	equipment_rig.set_shield_raised(raised)

func _refresh_equipped_visuals() -> void:
	equipment_rig.refresh_equipped_visuals()

## Oculta os visuais de armamento (personagem desarmado no refúgio)
func hide_equipment_visuals() -> void:
	equipment_rig.hide_equipment_visuals()

## Limpa todo o equipamento (usado no despertar na casa familiar)
func clear_all_equipment() -> void:
	equipment_rig.clear_all_equipment()

## Restaura e exibe os visuais de armamento ao se preparar no baú
func show_equipment_visuals() -> void:
	equipment_rig.show_equipment_visuals()

func _update_main_weapon_visual() -> void:
	equipment_rig.update_main_weapon_visual()

func _update_secondary_weapon_visual() -> void:
	equipment_rig.update_secondary_weapon_visual()

func _update_shield_visual() -> void:
	equipment_rig.update_shield_visual()

func set_slash_visual(is_active: bool, combo_step: int = 0, is_upward: bool = false, is_downward: bool = false, charge_ratio: float = 0.0) -> void:
	combat_vfx.set_slash_visual(is_active, combo_step, is_upward, is_downward, charge_ratio)

func play_animation(anim_name: StringName) -> void:
	if not player_sprite:
		return
	player_sprite.visible = true
	if body_polygon:
		body_polygon.visible = false
	var headband := visual.get_node_or_null("HeadbandPlaceholder") as CanvasItem
	if headband:
		headband.visible = false

	if hurt_flinch_timer > 0.0:
		if anim_name in [&"idle", &"run", &"fall", &"fall_from_jump", &"crouch", &"wall_cling", &"wall_slide"]:
			_pending_anim_after_flinch = anim_name
			return
		hurt_flinch_timer = 0.0
		_pending_anim_after_flinch = &""

	# Position handling: corner_climb has custom anchor; other animations use standard (-2, -29)
	if anim_name == &"corner_climb":
		player_sprite.position = Vector2(-6.5, 4.0)
	else:
		player_sprite.position = Vector2(-2, -29)

	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name or not animation_player.is_playing():
			animation_player.play(anim_name)
	else:
		if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation(anim_name):
			player_sprite.play(anim_name)
			_update_weapon_socket_for_frame(anim_name, player_sprite.frame)

func _on_slash_effect_frame_changed() -> void:
	combat_vfx.on_slash_effect_frame_changed()

func update_slash_frame_transform(frame_idx: int) -> void:
	combat_vfx.update_slash_frame_transform(frame_idx)

func _on_player_sprite_animation_finished() -> void:
	# Transição suave: após a ponte de desenrolar do pulo, mantém o loop de queda fluida
	if player_sprite and player_sprite.animation == &"fall_from_jump":
		player_sprite.play(&"fall")
	elif player_sprite and player_sprite.animation == &"block":
		play_animation(&"block_loop")

func _detect_weapon_type_string(w: WeaponData) -> String:
	return w.get_archetype_id() if w else "sword"

func _is_dagger(w: WeaponData) -> bool:
	return _detect_weapon_type_string(w) == "dagger"

func get_equipped_weapon_category() -> String:
	return _detect_weapon_type_string(weapon)

func _on_player_sprite_frame_changed() -> void:
	if not player_sprite:
		return
	_update_weapon_socket_for_frame(player_sprite.animation, player_sprite.frame)

func _on_animation_frame_changed() -> void:
	_on_player_sprite_frame_changed()

func _apply_visual_instance_flip(instance: Node2D, flip_h: bool, flip_v: bool) -> void:
	equipment_rig.apply_visual_instance_flip(instance, flip_h, flip_v)

func _update_weapon_socket_for_frame(anim_name: StringName, frame_idx: int) -> void:
	equipment_rig.update_sockets_for_frame(anim_name, frame_idx)

func stop_animation() -> void:
	if hurt_flinch_timer > 0.0:
		return
	if animation_player and animation_player.is_playing():
		animation_player.stop()
	if player_sprite:
		player_sprite.visible = false
		player_sprite.stop()
	if body_polygon:
		body_polygon.visible = true
	var headband := visual.get_node_or_null("HeadbandPlaceholder") as CanvasItem
	if headband:
		headband.visible = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Decrement timers
	if is_on_floor():
		coyote_timer = coyote_duration
		can_double_jump = true
		last_wall_jump_normal_x = 0.0 # Reset wall memory on ground touch
		is_wall_recovery_active = false
		set_meta("air_stall_steps", 0)
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if _ignore_roll_timer > 0.0:
		_ignore_roll_timer = max(0.0, _ignore_roll_timer - delta)

	if is_input_locked:
		jump_buffer_timer = 0.0
		attack_buffer_timer = 0.0
	else:
		if jump_buffer_timer > 0.0:
			jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = jump_buffer_duration

		if attack_buffer_timer > 0.0:
			attack_buffer_timer = max(0.0, attack_buffer_timer - delta)

		if Input.is_action_just_pressed("attack_primary"):
			attack_buffer_timer = attack_buffer_duration

	# Hit flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

	# Post-hit invulnerability frames (i-frames) + blink feedback
	if post_hit_invuln_timer > 0.0:
		post_hit_invuln_timer = maxf(0.0, post_hit_invuln_timer - delta)
		if visual:
			if post_hit_invuln_timer > 0.0:
				var blink_on: bool = int(floor(post_hit_invuln_timer * 20.0)) % 2 == 0
				visual.modulate.a = 0.45 if blink_on else 1.0
			else:
				visual.modulate.a = 1.0
		if post_hit_invuln_timer <= 0.0:
			_refresh_invulnerability()

	# Quick visual flinch on light hits (hurt frame 0 without stagger lock)
	if hurt_flinch_timer > 0.0:
		hurt_flinch_timer = maxf(0.0, hurt_flinch_timer - delta)
		if hurt_flinch_timer <= 0.0 and _pending_anim_after_flinch != &"":
			var next_anim := _pending_anim_after_flinch
			_pending_anim_after_flinch = &""
			play_animation(next_anim)

	# Attack cadence cooldown timer
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)

	# Parry fail cooldown timer (strict 1.0s penalty on whiff)
	if parry_cooldown_timer > 0.0:
		parry_cooldown_timer = max(0.0, parry_cooldown_timer - delta)

	# Tactical Life Rally timer countdown (2.0s window to parry and recover lost health)
	if rally_timer > 0.0:
		rally_timer = max(0.0, rally_timer - delta)
		if rally_timer <= 0.0:
			rally_recoverable_hp = 0.0

## Verifica se o balão de fala diegético (Bark) ainda está visível ou se dissipando
func is_bark_active() -> bool:
	if not bark_label:
		bark_label = get_node_or_null("BarkLabel") as Label
	if not bark_label or not bark_label.visible:
		return false
	return bark_label.modulate.a > 0.01 and _bark_tween != null and _bark_tween.is_valid() and _bark_tween.is_running()

## Exibe aviso diegético (Bark) suavemente animado flutuando acima da cabeça do guerreiro
func show_bark(text: String, custom_duration: float = 0.0) -> void:
	if not bark_label:
		bark_label = get_node_or_null("BarkLabel") as Label
	if not bark_label:
		return
	bark_label.visible = true
	bark_label.text = text
	bark_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	bark_label.position = Vector2(-100.0, -56.0)
	
	if _bark_tween and _bark_tween.is_valid():
		_bark_tween.kill()
		
	var duration: float = custom_duration if custom_duration > 0.0 else maxf(3.5, clampf(float(text.length()) * 0.08, 3.5, 6.0))
	_bark_tween = create_tween()
	_bark_tween.set_parallel(true)
	_bark_tween.tween_property(bark_label, "position:y", -70.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bark_tween.tween_property(bark_label, "modulate:a", 0.0, 0.8).set_delay(maxf(1.0, duration - 0.8))
	_bark_tween.chain().tween_callback(func() -> void:
		if bark_label:
			bark_label.visible = false
	)

func swap_weapons() -> void:
	if not secondary_weapon:
		return
	var temp: WeaponData = weapon
	weapon = secondary_weapon
	secondary_weapon = temp
	_update_main_weapon_visual()
	_update_secondary_weapon_visual()

func cycle_reserve_weapon() -> void:
	var weapon_paths: Array[String] = [
		"res://src/entities/equipment/bows/weapon_bow_base.tres",
		"res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
		"res://src/entities/equipment/swords/weapon_sword_base.tres",
		"res://src/entities/equipment/axes/weapon_axe_base.tres",
		"res://src/entities/equipment/hammers/weapon_hammer_base.tres",
		"res://src/entities/equipment/staffs/weapon_staff_base.tres",
		"res://src/entities/equipment/daggers/weapon_dagger_base.tres"
	]
	var current_idx: int = -1
	if secondary_weapon:
		for i in range(weapon_paths.size()):
			if weapon_paths[i].get_file().get_basename() in secondary_weapon.resource_path:
				current_idx = i
				break

	var next_idx: int = (current_idx + 1) % weapon_paths.size()
	var next_res := load(weapon_paths[next_idx]) as WeaponData
	if weapon and next_res and next_res.equipment_name == weapon.equipment_name:
		next_idx = (next_idx + 1) % weapon_paths.size()
		next_res = load(weapon_paths[next_idx]) as WeaponData

	equip_secondary_weapon(next_res)

func toggle_shield_repulsion() -> void:
	if shield:
		shield.has_repulsion_modifier = not shield.has_repulsion_modifier

func _unhandled_input(event: InputEvent) -> void:
	if is_input_locked:
		return
	if event.is_action_pressed("swap_weapon") and not event.is_echo():
		swap_weapons()
	elif event.is_action_pressed("cycle_weapon_debug") and not event.is_echo():
		cycle_reserve_weapon()
	elif event.is_action_pressed("toggle_shield_repulsion_debug") and not event.is_echo():
		toggle_shield_repulsion()
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_T:
		cycle_enemy_tier_live()
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_Y:
		cycle_axe_energize_profile_debug()

var player_level: int = 1

func cycle_enemy_tier_live() -> void:
	match player_level:
		1:
			player_level = 4 # Tier 2 (Veterano)
		4:
			player_level = 8 # Tier 3 (Elite)
		_:
			player_level = 1 # Tier 1 (Recruta)

	var tier_num: int = 1
	var tier_name: String = tr("UI_TIER_RECRUIT")
	if player_level >= 8:
		tier_num = 3
		tier_name = tr("UI_TIER_ELITE")
	elif player_level >= 4:
		tier_num = 2
		tier_name = tr("UI_TIER_VETERAN")

	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("apply_tier_by_level"):
			enemy.apply_tier_by_level(player_level)
		if enemy.has_method("respawn") and enemy.respawn_enabled:
			enemy.respawn()

	# Display on HUD
	var hud := get_node_or_null("HUD") as PlayerHUD
	if not hud and get_tree() and get_tree().current_scene:
		hud = get_tree().current_scene.find_child("HUD", true, false) as PlayerHUD
	if hud and hud.has_method("show_tier_toast"):
		hud.show_tier_toast(tier_num, tier_name, player_level)

func can_attack() -> bool:
	return weapon != null and attack_cooldown_timer <= 0.0

func is_ranged_weapon_equipped() -> bool:
	if not weapon:
		return false
	return weapon.weapon_category != WeaponData.WeaponCategory.MELEE

func can_defend() -> bool:
	return shield != null and parry_cooldown_timer <= 0.0

func get_effective_parry_window() -> float:
	if parry_window_override > 0.0:
		return parry_window_override
	return shield.parry_window if shield else 0.24

func get_effective_parry_fail_cooldown() -> float:
	if parry_fail_cooldown_override >= 0.0:
		return parry_fail_cooldown_override
	return shield.parry_fail_cooldown if shield else 0.6

func is_ground_slam_requested() -> bool:
	var down_held: bool = Input.is_action_pressed("down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) > 0.4
	return down_held and Input.is_action_just_pressed("jump")

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	if is_dead:
		return

	var incoming_hitbox: Hitbox = hurtbox.last_hitbox
	if state_machine and state_machine.current_state and state_machine.current_state.has_method("handle_incoming_hit"):
		var handled: bool = state_machine.current_state.handle_incoming_hit(damage, knockback, hitstop, incoming_hitbox)
		if handled:
			return

	current_health = max(0.0, current_health - damage)
	velocity = knockback

	if current_health <= 0.0:
		die()
		return

	if low_health_vignette:
		low_health_vignette.trigger_hit_spike()

	# Tactical Life Rally: Stores ONLY the damage of the most recent hit for 2.0s (resets on each hit)
	rally_recoverable_hp = minf(damage, max_health - current_health)
	rally_timer = RALLY_DURATION

	# Visual juice: Hit flash pure white
	if flash_material:
		flash_timer = hitstop + 0.08
		flash_material.set_shader_parameter("flash_active", true)

	# Tactile juice: Gamepad rumble & hitstop
	CombatFeedback.apply_hit_feedback(hitstop, 0.4, 0.7, 0.12)

	# Post-hit i-frames to prevent unfair stunlock/juggling
	if post_hit_invuln_duration > 0.0:
		post_hit_invuln_timer = post_hit_invuln_duration
		_refresh_invulnerability()

	# Stagger / Hurt animation with Last-Frame Hold:
	# Uses Hitbox.stagger_duration if > 0.0; PERILOUS attacks fall back to 0.45s (or 0.65s after failed parry).
	var stun_time: float = 0.0
	if incoming_hitbox:
		if incoming_hitbox.stagger_duration > 0.0:
			stun_time = incoming_hitbox.stagger_duration
			if incoming_hitbox.attack_category == Hitbox.AttackCategory.PERILOUS and parry_cooldown_timer > 0.0:
				stun_time = maxf(stun_time, 0.65)
		elif incoming_hitbox.attack_category == Hitbox.AttackCategory.PERILOUS:
			stun_time = 0.65 if parry_cooldown_timer > 0.0 else 0.45
	if stun_time > 0.0:
		hurt_flinch_timer = 0.0
		_pending_anim_after_flinch = &""
		trigger_stagger(stun_time)
	elif hurt_flinch_duration > 0.0:
		var state_name: String = String(state_machine.current_state.name) if (state_machine and state_machine.current_state) else ""
		if state_name in ["Idle", "Run", "Fall", "Jump", "DoubleJump", "Crouch", "WallSlide"]:
			_pending_anim_after_flinch = player_sprite.animation if player_sprite else &"idle"
			hurt_flinch_timer = hurt_flinch_duration
			if player_sprite and player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation(&"hurt"):
				player_sprite.position = Vector2(-2, -29)
				player_sprite.animation = &"hurt"
				player_sprite.pause()
				player_sprite.frame = 0
				_update_weapon_socket_for_frame(&"hurt", 0)

func set_dodge_invulnerable(active: bool) -> void:
	is_dodge_invulnerable = active
	_refresh_invulnerability()

func _refresh_invulnerability() -> void:
	if hurtbox:
		hurtbox.is_invulnerable = is_dodge_invulnerable or post_hit_invuln_timer > 0.0

func trigger_stagger(custom_duration: float) -> void:
	var stagger := state_machine.get_node_or_null("Stagger") as StaggerState
	if stagger:
		stagger.duration = custom_duration
	state_machine.transition_to("stagger")

## Recovers recent damage if player lands a Perfect Parry within the 2.0s rally window
func apply_parry_rally() -> float:
	if rally_recoverable_hp <= 0.0 or rally_timer <= 0.0:
		return 0.0
		
	var recovered: float = rally_recoverable_hp
	current_health = minf(current_health + recovered, max_health)
	rally_recoverable_hp = 0.0
	rally_timer = 0.0
	ProgressionManager.record_rally_heal(recovered)
	
	# Visual juice: triggers pure diegetic health bar punch + emerald/white flash
	var hud := get_node_or_null("HUD") as PlayerHUD
	if not hud and get_tree() and get_tree().current_scene:
		hud = get_tree().current_scene.find_child("HUD", true, false) as PlayerHUD
	if hud and hud.has_method("trigger_rally_restored_effect"):
		hud.trigger_rally_restored_effect()
		
	return recovered

## Dispara a sequência canônica da Morte do Guerreiro (Vórtice Espiral & Decisão Liminar)
func die() -> void:
	if is_dead:
		return
	is_dead = true
	rally_recoverable_hp = 0.0
	rally_timer = 0.0
	velocity = Vector2.ZERO
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if state_machine and state_machine.has_node("Death"):
		state_machine.transition_to("death")
	else:
		trigger_death_screen()

func trigger_death_screen() -> void:
	if death_screen:
		death_screen.play_death_sequence()
	else:
		_on_death_respawn()

func spawn_death_dropped_equipment() -> void:
	equipment_rig.spawn_death_dropped_equipment()

func clear_death_dropped_equipment() -> void:
	equipment_rig.clear_death_dropped_equipment()

func _on_death_respawn() -> void:
	clear_death_dropped_equipment()
	are_weapons_hidden = false
	if low_health_vignette:
		low_health_vignette.reset_death_takeover()
	ProgressionManager.reset_daily_run()
	current_health = max_health
	current_flask_charges = max_flask_charges
	rally_recoverable_hp = 0.0
	rally_timer = 0.0
	flask_charges_changed.emit(current_flask_charges, max_flask_charges)
	velocity = Vector2.ZERO
	is_dead = false
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	state_machine.transition_to("idle")

	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path != "res://src/world/hub/family_house.tscn":
		get_tree().change_scene_to_file("res://src/world/hub/family_house.tscn")
	else:
		global_position = _spawn_position

func _on_death_main_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func set_crouched(crouched: bool) -> void:
	if not collision_shape:
		return
	var rect := collision_shape.shape as RectangleShape2D
	if not rect:
		return

	if crouched:
		rect.size = Vector2(16.0, 20.0)
		collision_shape.position = Vector2(0.0, -10.0)
		if not player_sprite or not player_sprite.visible:
			visual.scale.y = 0.5
		if hurtbox and hurtbox.has_node("CollisionShape2D"):
			var h_rect := hurtbox.get_node("CollisionShape2D").shape as RectangleShape2D
			if h_rect:
				h_rect.size = Vector2(16.0, 20.0)
				hurtbox.get_node("CollisionShape2D").position = Vector2(0.0, -10.0)
	else:
		rect.size = Vector2(16.0, 40.0)
		collision_shape.position = Vector2(0.0, -20.0)
		visual.scale.y = 1.0
		if hurtbox and hurtbox.has_node("CollisionShape2D"):
			var h_rect := hurtbox.get_node("CollisionShape2D").shape as RectangleShape2D
			if h_rect:
				h_rect.size = Vector2(16.0, 40.0)
				hurtbox.get_node("CollisionShape2D").position = Vector2(0.0, -20.0)

## Soft body collision detection:
## Returns true if the player is actively pressing into an enemy body horizontally.
func is_pushing_against_enemy(move_direction: float) -> bool:
	if not enemy_overlap_detector or move_direction == 0.0:
		return false
	var overlapping := enemy_overlap_detector.get_overlapping_bodies()
	for body in overlapping:
		if body is CharacterBody2D and body != self:
			var dx: float = body.global_position.x - global_position.x
			# If moving towards the enemy center or currently deep inside them
			if move_direction > 0.0 and dx > -8.0:
				return true
			elif move_direction < 0.0 and dx < 8.0:
				return true
	return false

func update_facing(direction: float) -> void:
	var new_facing: int = 0
	if direction > 0.0:
		new_facing = 1
	elif direction < 0.0:
		new_facing = -1

	if new_facing != 0:
		var needs_update: bool = (new_facing != facing_direction or visual.scale.x != float(new_facing))
		if needs_update:
			facing_direction = new_facing
			visual.scale.x = float(facing_direction)
			_update_equipment_depth()

func _update_equipment_depth() -> void:
	equipment_rig.update_equipment_depth()

## Intent-filtered check for crouching.
## Prevents accidental crouches when tilting the analog stick diagonally while running.
func is_crouch_requested() -> bool:
	if not Input.is_action_pressed("down"):
		return false

	# Digital keys (Keyboard S / Arrow Down)
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return true

	# Left Analog Stick:
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)

	# Must reach minimum vertical threshold (positive Y is down)
	if joy_y < vertical_input_threshold:
		return false

	# If also running/holding horizontal direction, require dominant downward intent
	if absf(joy_x) > 0.35:
		return joy_y > absf(joy_x) * 0.85

	return true

## Intent-filtered check for upward aiming / attacking.
## Prevents accidental upward slashes when tilting the analog stick diagonally while attacking.
func is_upward_attack_requested() -> bool:
	if not Input.is_action_pressed("up"):
		return false

	# Digital keys (Keyboard W / Arrow Up)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		return true

	# Left Analog Stick (negative Y is up):
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)

	# Must reach minimum upward threshold
	if joy_y > -vertical_input_threshold:
		return false

	# If holding horizontal direction, require dominant upward intent
	if absf(joy_x) > 0.35:
		return absf(joy_y) > absf(joy_x) * 0.85

	return true

func set_ledge_climb_visual(active: bool) -> void:
	if ledge_climb_visual:
		ledge_climb_visual.visible = false
	if active:
		play_animation(&"corner_climb")
	if body_polygon:
		body_polygon.visible = not active
	if visual.has_node("HeadbandPlaceholder"):
		(visual.get_node("HeadbandPlaceholder") as CanvasItem).visible = not active

## Ledge detection (Dead Cells mantle check):
## Detects when any part of the player (feet, knees, waist, or chest) hits a wall edge
## while open air is above, finding the exact floor surface to vault onto.
func check_ledge() -> bool:
	if is_crouch_requested():
		return false

	var space := get_world_2d().direct_space_state
	if not space:
		return false

	var face: float = float(facing_direction)
	var ray_dist: float = 18.0

	# 1. Wall Contact: Check lowest contact point at the very bottom of the feet (y = -1.0),
	# knee height (y = -12.0), and chest height (y = -24.0) so even a 1-pixel contact with a ledge is caught.
	var wall_hit: Dictionary = {}
	var low_query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -1.0),
		global_position + Vector2(face * ray_dist, -1.0),
		1
	)
	low_query.exclude = [get_rid()]
	wall_hit = space.intersect_ray(low_query)

	if wall_hit.is_empty():
		var knee_query := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0.0, -12.0),
			global_position + Vector2(face * ray_dist, -12.0),
			1
		)
		knee_query.exclude = [get_rid()]
		wall_hit = space.intersect_ray(knee_query)

	if wall_hit.is_empty():
		var chest_query := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0.0, -24.0),
			global_position + Vector2(face * ray_dist, -24.0),
			1
		)
		chest_query.exclude = [get_rid()]
		wall_hit = space.intersect_ray(chest_query)

	if wall_hit.is_empty():
		return false

	var wall_x: float = wall_hit.position.x

	# 2. Head Clearance: Upper body / head must have clear space (no wall above the platform edge)
	var head_from := global_position + Vector2(0.0, -42.0)
	var head_to := head_from + Vector2(face * (ray_dist + 4.0), 0.0)
	var head_query := PhysicsRayQueryParameters2D.create(head_from, head_to, 1)
	head_query.exclude = [get_rid()]
	var head_hit := space.intersect_ray(head_query)
	if not head_hit.is_empty():
		return false

	# 3. Floor Surface Finder: Cast downwards onto the platform top (from above head down to beneath feet)
	var floor_from := Vector2(wall_x + (face * 6.0), global_position.y - 50.0)
	var floor_to := Vector2(wall_x + (face * 6.0), global_position.y + 6.0)
	var floor_query := PhysicsRayQueryParameters2D.create(floor_from, floor_to, 1)
	floor_query.exclude = [get_rid()]
	var floor_hit := space.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return false

	# Surface must be a walkable floor (normal pointing upwards)
	if floor_hit.normal.y > -0.7:
		return false

	var floor_y: float = floor_hit.position.y

	# 4. Headroom Clearance: Verify 40px standing room above the floor surface
	var target_x: float = wall_x + (face * 10.0)
	var ceiling_from := Vector2(target_x, floor_y - 2.0)
	var ceiling_to := Vector2(target_x, floor_y - 42.0)
	var ceiling_query := PhysicsRayQueryParameters2D.create(ceiling_from, ceiling_to, 1)
	ceiling_query.exclude = [get_rid()]
	var ceiling_hit := space.intersect_ray(ceiling_query)
	if not ceiling_hit.is_empty():
		return false

	ledge_target_position = Vector2(target_x, floor_y)
	return true

func _apply_slash_energize_shader(charge_ratio: float) -> void:
	combat_vfx.apply_slash_energize_shader(charge_ratio)

func update_weapon_energize(charge_progress: float, base_scale: Vector2) -> void:
	combat_vfx.update_weapon_energize(charge_progress, base_scale)

func trigger_weapon_energize_release() -> void:
	combat_vfx.trigger_weapon_energize_release()

func stop_weapon_energize_particles() -> void:
	combat_vfx.stop_weapon_energize_particles()

func clear_weapon_energize(base_scale: Vector2) -> void:
	combat_vfx.clear_weapon_energize(base_scale)

func cycle_axe_energize_profile_debug() -> void:
	combat_vfx.cycle_axe_energize_profile_debug()

func spawn_ground_impact_particles(center_x: float, ground_y: float, width: float, facing: int = 1, fallback_scene_path: String = "") -> void:
	combat_vfx.spawn_ground_impact_particles(center_x, ground_y, width, facing, fallback_scene_path)

func set_pickup_item_visual(source_visual: Node2D, effect_profile: PickupEffectProfile = null) -> void:
	combat_vfx.set_pickup_item_visual(source_visual, effect_profile)

func clear_pickup_item_visual() -> void:
	combat_vfx.clear_pickup_item_visual()

func play_pickup_item_burst() -> void:
	combat_vfx.play_pickup_item_burst()

func trigger_pickup_animation(source_visual: Node2D = null, effect_profile: PickupEffectProfile = null) -> void:
	set_pickup_item_visual(source_visual, effect_profile)
	if state_machine and state_machine.has_node("Pickup"):
		state_machine.transition_to("pickup")
