class_name Soldier
extends CharacterBody2D

## Basic melee soldier enemy implementing FSM, 3-signal tactical combat, and diegetic feedback.

enum CooldownBehavior {
	AGGRESSIVE_STALK,  ## Camina lentamente na direção do player
	DEFENSIVE_RETREAT, ## Recua mantendo distância de segurança (kiting/footsies)
	STAND_GROUND,      ## Permanece firme no lugar (para sentinelas/plantas/mãos de boss)
	ADAPTIVE           ## Agressivo, mas se bloqueado/parried, esquiva para trás e reposiciona
}

@export_group("Base Stats")
@export var is_elite: bool = false ## Se marcado true, este inimigo sempre será Elite nesta sala/mapa
@export var can_move: bool = true
@export var takes_knockback: bool = true
@export var enemy_category: EnemyCategories.Category = EnemyCategories.Category.HUMANOID
@export var stationary: bool = false:
	set(val):
		stationary = val
		can_move = not val
@export_range(-1, 1, 2) var initial_facing: int = 1
@export_range(10.0, 1000.0, 5.0) var max_health: float = 60.0
@export_range(10.0, 300.0, 5.0, "suffix:px/s") var patrol_speed: float = 40.0
@export_range(30.0, 400.0, 5.0, "suffix:px/s") var chase_speed: float = 85.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var friction: float = 800.0

@export_group("Perception & Range")
@export_range(50.0, 400.0, 10.0, "suffix:px") var spot_range: float = 160.0
@export_range(20.0, 200.0, 5.0, "suffix:px") var back_awareness_range: float = 64.0
@export_range(10.0, 100.0, 2.0, "suffix:px") var attack_range: float = 26.0
@export_range(100.0, 600.0, 10.0, "suffix:px") var lose_target_range: float = 240.0

@export_group("Attack Balancing")
@export_range(5.0, 100.0, 1.0) var normal_damage: float = 12.0
@export_range(10.0, 150.0, 1.0) var heavy_damage: float = 20.0
@export_range(15.0, 200.0, 1.0) var perilous_damage: float = 32.0
@export_range(0.1, 1.5, 0.05, "suffix:s") var telegraph_duration: float = 0.45
@export_range(0.0, 20.0, 0.05, "suffix:s") var attack_cooldown: float = 2.0
@export_range(0.1, 1.0, 0.05) var cooldown_speed_mult: float = 0.45

@export_group("Tier 1 (Base - Lv 1+)")
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_1_attacks: int = 1
@export var tier_1_behavior: CooldownBehavior = CooldownBehavior.AGGRESSIVE_STALK
@export var tier_1_damage_mult: float = 1.0
@export var tier_1_health_mult: float = 1.0

@export_group("Tier 2 (Veteran - Lv 4+)")
@export var tier_2_min_level: int = 4
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_2_attacks: int = 2
@export var tier_2_behavior: CooldownBehavior = CooldownBehavior.AGGRESSIVE_STALK
@export var tier_2_damage_mult: float = 1.25
@export var tier_2_health_mult: float = 1.30

@export_group("Tier 3 (Elite - Lv 8+)")
@export var tier_3_min_level: int = 8
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_3_attacks: int = 4
@export var tier_3_behavior: CooldownBehavior = CooldownBehavior.ADAPTIVE
@export var tier_3_damage_mult: float = 1.60
@export var tier_3_health_mult: float = 1.75
@export var tier_3_has_hyper_armor: bool = true
@export var tier_3_can_be_elite: bool = true
@export_range(0.0, 1.0, 0.05) var tier_3_elite_chance: float = 0.25

@export_group("Respawn (Test Mode)")
@export var respawn_enabled: bool = false
@export_range(1.0, 30.0, 0.5, "suffix:s") var respawn_delay: float = 5.0

var spawn_position: Vector2 = Vector2.ZERO
var base_max_health: float = 60.0
var current_health: float = 60.0
var facing_direction: int = 1
var target_player: Player = null
var is_hyper_armored: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial

# Active Tier State
var active_tier: int = 1
var allowed_attacks_mask: int = 1
var active_behavior: CooldownBehavior = CooldownBehavior.AGGRESSIVE_STALK
var active_damage_multiplier: float = 1.0
var is_elite_active: bool = false
var is_adaptive_evading: bool = false
var adaptive_evade_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var telegraph_mark: Node2D = $Visual/TelegraphMark
@onready var white_mark: Polygon2D = $Visual/TelegraphMark/WhiteMark
@onready var yellow_mark: Polygon2D = $Visual/TelegraphMark/YellowMark
@onready var red_mark: Polygon2D = $Visual/TelegraphMark/RedMark
@onready var slash_arc: Polygon2D = $Visual/SlashArc
@onready var slash_arc_up: Polygon2D = $Visual/SlashArcUp
@onready var slash_arc_down: Polygon2D = $Visual/SlashArcDown
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var hitbox_up: Hitbox = $Visual/HitboxUp
@onready var hitbox_down: Hitbox = $Visual/HitboxDown
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	base_max_health = max_health
	apply_tier_by_level(1)
	if initial_facing != 0:
		update_facing(float(initial_facing))
	hurtbox.hit_received.connect(_on_hit_received)
	hide_telegraph()
	set_slash_active(false)
	set_slash_up_active(false)
	set_slash_down_active(false)

	# Setup hit flash shader material
	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	if shader and body_polygon:
		flash_material = ShaderMaterial.new()
		flash_material.shader = shader
		body_polygon.material = flash_material

	# Set hitbox attacker reference
	if hitbox:
		hitbox.attacker = self
	if hitbox_up:
		hitbox_up.attacker = self
	if hitbox_down:
		hitbox_down.attacker = self

func _physics_process(delta: float) -> void:
	# Flash timer update
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

	# Adaptive evasion timer
	if is_adaptive_evading:
		adaptive_evade_timer -= delta
		if adaptive_evade_timer <= 0.0:
			is_adaptive_evading = false

	# Squash & stretch recovery
	visual.scale.y = move_toward(visual.scale.y, 1.0, 4.0 * delta)

func apply_tier_by_level(player_level: int) -> void:
	if player_level >= tier_3_min_level:
		active_tier = 3
	elif player_level >= tier_2_min_level:
		active_tier = 2
	else:
		active_tier = 1

	allowed_attacks_mask = tier_1_attacks
	active_behavior = tier_1_behavior
	active_damage_multiplier = tier_1_damage_mult
	var hp_mult: float = tier_1_health_mult
	is_hyper_armored = false
	is_elite_active = false

	if active_tier >= 2:
		allowed_attacks_mask |= tier_2_attacks
		active_behavior = tier_2_behavior
		active_damage_multiplier = tier_2_damage_mult
		hp_mult = tier_2_health_mult

	if active_tier >= 3:
		allowed_attacks_mask |= tier_3_attacks
		active_behavior = tier_3_behavior
		active_damage_multiplier = tier_3_damage_mult
		hp_mult = tier_3_health_mult
	if is_elite:
		is_elite_active = true
	elif active_tier >= 3 and tier_3_can_be_elite:
		is_elite_active = (randf() < tier_3_elite_chance)
	else:
		is_elite_active = false

	if is_elite_active:
		hp_mult *= 1.30
		active_damage_multiplier *= 1.20
		is_hyper_armored = true

	max_health = base_max_health * hp_mult
	current_health = max_health

	# Visual indicator for Elite / Tier
	if is_elite_active and body_polygon:
		body_polygon.color = Color(0.85, 0.2, 0.2, 1.0) # Elite Crimson
		visual.scale = Vector2(float(facing_direction) * 1.15, 1.15) # 15% larger!
	elif active_tier == 3 and body_polygon:
		body_polygon.color = Color(0.55, 0.25, 0.45, 1.0) # Tier 3 Regular Burgundy
		visual.scale = Vector2(float(facing_direction), 1.0)
	elif active_tier == 2 and body_polygon:
		body_polygon.color = Color(0.35, 0.45, 0.6, 1.0) # Veteran Blue Hue
		visual.scale = Vector2(float(facing_direction), 1.0)
	elif body_polygon:
		body_polygon.color = Color(0.3, 0.35, 0.4, 1.0) # Recruit Slate Hue
		visual.scale = Vector2(float(facing_direction), 1.0)

func on_attack_blocked(is_parry: bool) -> void:
	if active_behavior == CooldownBehavior.ADAPTIVE and can_move:
		is_adaptive_evading = true
		adaptive_evade_timer = 1.0 if is_parry else 0.6

func can_step_forward() -> bool:
	if not is_on_floor():
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var check_x: float = global_position.x + (facing_direction * 14.0)
	var query_floor := PhysicsRayQueryParameters2D.create(
		Vector2(check_x, global_position.y - 2.0),
		Vector2(check_x, global_position.y + 16.0),
		1 # Layer 1: Environment
	)
	var floor_hit := space.intersect_ray(query_floor)
	if floor_hit.is_empty():
		return false # Ledge/cliff ahead
	var query_wall := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x, global_position.y - 16.0),
		Vector2(check_x, global_position.y - 16.0),
		1
	)
	var wall_hit := space.intersect_ray(query_wall)
	return wall_hit.is_empty()

func can_step_backward() -> bool:
	if not is_on_floor():
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var check_x: float = global_position.x - (facing_direction * 14.0)
	var query_floor := PhysicsRayQueryParameters2D.create(
		Vector2(check_x, global_position.y - 2.0),
		Vector2(check_x, global_position.y + 16.0),
		1 # Layer 1: Environment
	)
	var floor_hit := space.intersect_ray(query_floor)
	if floor_hit.is_empty():
		return false # Ledge/cliff behind
	var query_wall := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x, global_position.y - 16.0),
		Vector2(check_x, global_position.y - 16.0),
		1
	)
	var wall_hit := space.intersect_ray(query_wall)
	return wall_hit.is_empty()

func respawn() -> void:
	global_position = spawn_position
	current_health = max_health
	target_player = null
	velocity = Vector2.ZERO
	is_adaptive_evading = false
	if visual:
		visual.visible = true
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
	set_collision_layer_value(3, true)
	if hurtbox:
		hurtbox.is_invulnerable = false
		if hurtbox.has_node("CollisionShape2D"):
			hurtbox.get_node("CollisionShape2D").set_deferred("disabled", false)
	update_facing(float(initial_facing))
	state_machine.transition_to("patrol")

func update_facing(dir: float) -> void:
	if dir > 0.0:
		facing_direction = 1
		visual.scale.x = 1.0
	elif dir < 0.0:
		facing_direction = -1
		visual.scale.x = -1.0

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	current_health -= damage

	# Hit flash
	if flash_material:
		flash_timer = hitstop + 0.06
		flash_material.set_shader_parameter("flash_active", true)

	visual.scale = Vector2(visual.scale.x, 0.75)

	# Check Death
	if current_health <= 0.0:
		state_machine.transition_to("death")
		return

	# Acquire target on hit if null
	if not target_player or not is_instance_valid(target_player):
		var tree := get_tree()
		if tree:
			var players := tree.get_nodes_in_group("player")
			if players.size() > 0 and players[0] is Player:
				target_player = players[0] as Player
			elif tree.current_scene:
				var p := tree.current_scene.find_child("Player", true, false)
				if p is Player:
					target_player = p as Player

	# Check attack interruption rules:
	# - Normal Attack: Interrupted by ANY hit (Hit 1, 2, or 3).
	# - Yellow Attack: ONLY interrupted by the 3rd hit (finisher) of player combo.
	# - Red Attack: CANNOT be interrupted under any circumstance.
	# - Damage is ALWAYS taken in all instances. Knockback & stunlock only occur when interrupted.
	var incoming_hitbox: Hitbox = hurtbox.last_hitbox
	var combo_step: int = incoming_hitbox.combo_step if incoming_hitbox else 1
	var is_finisher: bool = (combo_step >= 3)

	if not takes_knockback or not can_move:
		knockback = Vector2.ZERO

	var can_interrupt: bool = false

	if state_machine.current_state is SoldierAttackState:
		var attack_state: SoldierAttackState = state_machine.current_state as SoldierAttackState
		match attack_state.attack_type:
			SoldierAttackState.AttackType.NORMAL:
				can_interrupt = true
			SoldierAttackState.AttackType.YELLOW, SoldierAttackState.AttackType.UPWARD, SoldierAttackState.AttackType.DOWNWARD:
				can_interrupt = is_finisher
			SoldierAttackState.AttackType.RED:
				can_interrupt = false
	else:
		can_interrupt = true

	if can_interrupt:
		velocity = knockback
		if absf(knockback.x) > 1.0:
			update_facing(-signf(knockback.x))
		state_machine.transition_to("hurt")
	else:
		# Uninterrupted: takes damage and flashes, but resists knockback completely
		velocity = Vector2.ZERO

func apply_parry_stun(duration: float = 0.85) -> void:
	is_hyper_armored = false
	hide_telegraph()
	set_slash_active(false)
	set_slash_up_active(false)
	set_slash_down_active(false)
	if hitbox:
		hitbox.set_active(false)
	if hitbox_up:
		hitbox_up.set_active(false)
	if hitbox_down:
		hitbox_down.set_active(false)

	if flash_material:
		flash_timer = 0.25
		flash_material.set_shader_parameter("flash_active", true)

	visual.scale = Vector2(visual.scale.x, 0.7)
	velocity = Vector2.ZERO

	var hurt_state := state_machine.get_node_or_null("Hurt") as SoldierHurtState
	if hurt_state:
		hurt_state.custom_stun_duration = duration
	state_machine.transition_to("hurt")

## Telegraph visual helpers
func show_white_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if white_mark:
		white_mark.visible = true
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = false

func show_yellow_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if white_mark:
		white_mark.visible = false
	if yellow_mark:
		yellow_mark.visible = true
	if red_mark:
		red_mark.visible = false

func show_red_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if white_mark:
		white_mark.visible = false
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = true

func hide_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = false
	if white_mark:
		white_mark.visible = false
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = false

func set_slash_color(col: Color) -> void:
	if slash_arc:
		slash_arc.color = col
	if slash_arc_up:
		slash_arc_up.color = col
	if slash_arc_down:
		slash_arc_down.color = col

func set_slash_active(active: bool) -> void:
	if slash_arc:
		slash_arc.visible = active

func set_slash_up_active(active: bool) -> void:
	if slash_arc_up:
		slash_arc_up.visible = active

func set_slash_down_active(active: bool) -> void:
	if slash_arc_down:
		slash_arc_down.visible = active
