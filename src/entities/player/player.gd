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
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_health: float = 250.0
@export_range(0.0, 500.0, 1.0, "or_greater") var max_mana: float = 100.0
var current_health: float = 250.0
var current_mana: float = 100.0
var _debug_respawn_timer: float = 0.0

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

@export_group("Roll & Dodge")
@export_range(100.0, 800.0, 10.0, "suffix:px/s") var roll_speed: float = 240.0
@export_range(0.1, 1.0, 0.01, "suffix:s") var roll_duration: float = 0.28

@export_group("Combat & Equipment")
@export var weapon: WeaponData
@export var secondary_weapon: WeaponData
@export var shield: ShieldData

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
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
			_ignore_roll_timer = 0.25
			jump_buffer_timer = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/BodyPlaceholder
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var enemy_overlap_detector: Area2D = $EnemyOverlapDetector
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var slash_effect: Node2D = $Visual/SlashEffect
@onready var ledge_climb_visual: Node2D = $Visual/LedgeClimbPlaceholder
@onready var main_hand_socket: Marker2D = $Visual/MainHandSocket
@onready var off_hand_socket: Marker2D = $Visual/OffHandSocket
@onready var back_socket_shield: Marker2D = $Visual/BackSocketShield
@onready var back_socket_weapon: Marker2D = $Visual/BackSocketWeapon
@onready var bark_label: Label = get_node_or_null("BarkLabel") as Label
@onready var death_screen: DeathScreen = get_node_or_null("DeathScreen") as DeathScreen

var _main_weapon_instance: Node2D = null
var _secondary_weapon_instance: Node2D = null
var _shield_instance: Node2D = null
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

	_refresh_equipped_visuals()
	_update_equipment_depth()
	ProgressionManager.apply_to_player(self)

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

func equip_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	_update_main_weapon_visual()

func equip_secondary_weapon(new_secondary: WeaponData) -> void:
	secondary_weapon = new_secondary
	_update_secondary_weapon_visual()

func equip_shield(new_shield: ShieldData) -> void:
	shield = new_shield
	_update_shield_visual()

func set_shield_raised(raised: bool) -> void:
	if is_shield_raised == raised:
		return
	is_shield_raised = raised
	if not _shield_instance or not is_instance_valid(_shield_instance):
		return

	var target_socket: Marker2D = off_hand_socket if is_shield_raised else back_socket_shield
	if _shield_instance.get_parent() != target_socket:
		_shield_instance.reparent(target_socket, false)
	_shield_instance.position = shield.visual_offset if shield else Vector2.ZERO
	_shield_instance.rotation_degrees = shield.visual_rotation_degrees if shield else 0.0
	_shield_instance.z_index = 0

func _refresh_equipped_visuals() -> void:
	_update_main_weapon_visual()
	_update_secondary_weapon_visual()
	_update_shield_visual()

## Oculta os visuais de armamento (personagem desarmado no refúgio)
func hide_equipment_visuals() -> void:
	are_weapons_hidden = true
	if _main_weapon_instance and is_instance_valid(_main_weapon_instance):
		_main_weapon_instance.visible = false
	if _secondary_weapon_instance and is_instance_valid(_secondary_weapon_instance):
		_secondary_weapon_instance.visible = false
	if _shield_instance and is_instance_valid(_shield_instance):
		_shield_instance.visible = false

## Limpa todo o equipamento (usado no despertar na casa familiar)
func clear_all_equipment() -> void:
	weapon = null
	secondary_weapon = null
	shield = null
	if _main_weapon_instance and is_instance_valid(_main_weapon_instance):
		_main_weapon_instance.queue_free()
		_main_weapon_instance = null
	if _secondary_weapon_instance and is_instance_valid(_secondary_weapon_instance):
		_secondary_weapon_instance.queue_free()
		_secondary_weapon_instance = null
	if _shield_instance and is_instance_valid(_shield_instance):
		_shield_instance.queue_free()
		_shield_instance = null
	are_weapons_hidden = true

## Restaura e exibe os visuais de armamento ao se preparar no baú
func show_equipment_visuals() -> void:
	are_weapons_hidden = false
	if _main_weapon_instance and is_instance_valid(_main_weapon_instance):
		_main_weapon_instance.visible = true
	else:
		_update_main_weapon_visual()

	if _secondary_weapon_instance and is_instance_valid(_secondary_weapon_instance):
		_secondary_weapon_instance.visible = true
	else:
		_update_secondary_weapon_visual()

	if _shield_instance and is_instance_valid(_shield_instance):
		_shield_instance.visible = true
	else:
		_update_shield_visual()

func _update_main_weapon_visual() -> void:
	if _main_weapon_instance and is_instance_valid(_main_weapon_instance):
		_main_weapon_instance.queue_free()
		_main_weapon_instance = null

	if weapon and weapon.visual_scene and main_hand_socket:
		_main_weapon_instance = weapon.visual_scene.instantiate() as Node2D
		if _main_weapon_instance:
			main_hand_socket.add_child(_main_weapon_instance)
			_main_weapon_instance.position = weapon.visual_offset
			_main_weapon_instance.rotation_degrees = weapon.visual_rotation_degrees
			_main_weapon_instance.z_index = 0
			_main_weapon_instance.visible = not are_weapons_hidden

func _update_secondary_weapon_visual() -> void:
	if _secondary_weapon_instance and is_instance_valid(_secondary_weapon_instance):
		_secondary_weapon_instance.queue_free()
		_secondary_weapon_instance = null

	if secondary_weapon and secondary_weapon.visual_scene and back_socket_weapon:
		_secondary_weapon_instance = secondary_weapon.visual_scene.instantiate() as Node2D
		if _secondary_weapon_instance:
			back_socket_weapon.add_child(_secondary_weapon_instance)
			_secondary_weapon_instance.position = secondary_weapon.back_offset
			_secondary_weapon_instance.rotation_degrees = secondary_weapon.back_rotation_degrees
			_secondary_weapon_instance.z_index = 0
			_secondary_weapon_instance.visible = not are_weapons_hidden

func _update_shield_visual() -> void:
	if _shield_instance and is_instance_valid(_shield_instance):
		_shield_instance.queue_free()
		_shield_instance = null

	if shield and shield.visual_scene:
		_shield_instance = shield.visual_scene.instantiate() as Node2D
		if _shield_instance:
			var target_socket: Marker2D = off_hand_socket if is_shield_raised else back_socket_shield
			target_socket.add_child(_shield_instance)
			_shield_instance.position = shield.visual_offset
			_shield_instance.rotation_degrees = shield.visual_rotation_degrees
			_shield_instance.z_index = 0
			_shield_instance.visible = not are_weapons_hidden

func set_slash_visual(is_active: bool, combo_step: int = 0, is_upward: bool = false, is_downward: bool = false) -> void:
	if slash_effect:
		slash_effect.visible = is_active
		if is_active:
			if is_upward:
				slash_effect.position = Vector2(0.0, -32.0)
				slash_effect.rotation_degrees = -90.0
				slash_effect.scale = Vector2(1.2, 1.2)
			elif is_downward:
				if not is_on_floor():
					slash_effect.position = Vector2(0.0, 4.0)
					slash_effect.rotation_degrees = 90.0
					slash_effect.scale = Vector2(1.2, 1.2)
				else:
					slash_effect.position = Vector2(16.0, -8.0)
					slash_effect.rotation_degrees = 35.0
					slash_effect.scale = Vector2(1.1, 1.1)
			else:
				slash_effect.position = Vector2(0.0, -20.0)
				slash_effect.rotation_degrees = -20.0 if combo_step == 0 else (20.0 if combo_step == 1 else 0.0)
				slash_effect.scale = Vector2(1.0 + combo_step * 0.2, 1.0 + combo_step * 0.2)

	if main_hand_socket:
		if is_active:
			if is_upward:
				main_hand_socket.rotation_degrees = -90.0
			elif is_downward:
				main_hand_socket.rotation_degrees = 90.0
			else:
				main_hand_socket.rotation_degrees = -20.0 if combo_step == 0 else (20.0 if combo_step == 1 else 0.0)
		else:
			main_hand_socket.rotation_degrees = -35.0

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return

	# Decrement timers
	if is_on_floor():
		coyote_timer = coyote_duration
		can_double_jump = true
		last_wall_jump_normal_x = 0.0 # Reset wall memory on ground touch
		is_wall_recovery_active = false
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if _ignore_roll_timer > 0.0:
		_ignore_roll_timer = max(0.0, _ignore_roll_timer - delta)

	if is_input_locked:
		jump_buffer_timer = 0.0
	else:
		if jump_buffer_timer > 0.0:
			jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = jump_buffer_duration

	# Hit flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

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
	var tier_name: String = "RECRUTA"
	if player_level >= 8:
		tier_num = 3
		tier_name = "ELITE"
	elif player_level >= 4:
		tier_num = 2
		tier_name = "VETERANO"

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

	# Tactical Life Rally: Stores ONLY the damage of the most recent hit for 2.0s (resets on each hit)
	rally_recoverable_hp = minf(damage, max_health - current_health)
	rally_timer = RALLY_DURATION

	# Visual juice: Hit flash pure white
	if flash_material:
		flash_timer = hitstop + 0.08
		flash_material.set_shader_parameter("flash_active", true)

	# Tactile juice: Gamepad rumble & hitstop
	CombatFeedback.apply_hit_feedback(hitstop, 0.4, 0.7, 0.12)

	# Perilous (Red) Attack hit in neutral:
	# Triggers fast stun in crouched animation (0.22s) if no parry attempt,
	# or longer stun (0.55s) if player recently failed a parry.
	# Yellow attacks: DO NOT STUN.
	if incoming_hitbox and incoming_hitbox.attack_category == Hitbox.AttackCategory.PERILOUS:
		var stun_time: float = 0.55 if parry_cooldown_timer > 0.0 else 0.22
		trigger_stagger(stun_time)

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
	
	if death_screen:
		death_screen.play_death_sequence()
	else:
		_on_death_respawn()

func _on_death_respawn() -> void:
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
	# Right-handed anatomy & 2D perspective:
	# Facing RIGHT (facing_direction == 1):
	#   Right hand (MainHand / Weapon) is towards camera -> in front of torso (z_index = 1)
	#   Left hand (OffHand / Shield in guard) is away from camera -> behind torso (z_index = -1)
	# Facing LEFT (facing_direction == -1):
	#   Left hand (OffHand / Shield in guard) is towards camera -> in front of torso (z_index = 1)
	#   Right hand (MainHand / Weapon) is away from camera -> behind torso (z_index = -1)
	if facing_direction == 1:
		if main_hand_socket:
			main_hand_socket.z_index = 1
		if off_hand_socket:
			off_hand_socket.z_index = -1
	else:
		if main_hand_socket:
			main_hand_socket.z_index = -1
		if off_hand_socket:
			off_hand_socket.z_index = 1

	if back_socket_shield:
		back_socket_shield.z_index = -1
	if back_socket_weapon:
		back_socket_weapon.z_index = -2

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
		ledge_climb_visual.visible = active
	if body_polygon:
		body_polygon.visible = not active
	if visual.has_node("HeadbandPlaceholder"):
		(visual.get_node("HeadbandPlaceholder") as CanvasItem).visible = not active
	if main_hand_socket:
		main_hand_socket.visible = not active

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
