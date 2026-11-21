class_name BaseEnemy
extends CharacterBody2D

## Base class for ground enemies sharing Tier scaling, Elite visuals,
## stateless platform/LoS sensors, 3-signal telegraphs, parry stun, hit flash, and respawn.

enum CooldownBehavior {
	AGGRESSIVE_STALK,  ## Camina lentamente na direção do player
	DEFENSIVE_RETREAT, ## Recua mantendo distância de segurança (kiting/footsies)
	STAND_GROUND,      ## Permanece firme no lugar (para sentinelas/plantas/mãos de boss)
	ADAPTIVE           ## Agressivo, mas se bloqueado/parried, esquiva para trás e reposiciona
}

@export_group("Base Stats")
@export var is_elite: bool = false ## Se marcado true, este inimigo sempre será Elite nesta sala/mapa
@export var enemy_category: EnemyCategories.Category = EnemyCategories.Category.HUMANOID
@export var can_move: bool = true
@export var takes_knockback: bool = true
@export var stationary: bool = false:
	set(val):
		stationary = val
		can_move = not val
@export_range(-1, 1, 2) var initial_facing: int = -1
@export_range(10.0, 1000.0, 5.0) var max_health: float = 60.0
@export_range(10.0, 300.0, 5.0, "suffix:px/s") var patrol_speed: float = 35.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var friction: float = 800.0

@export_group("Perception & Range")
@export_range(50.0, 600.0, 10.0, "suffix:px") var spot_range: float = 200.0
@export_range(20.0, 300.0, 5.0, "suffix:px") var back_awareness_range: float = 80.0
@export_range(10.0, 200.0, 2.0, "suffix:px") var attack_range: float = 30.0
@export_range(100.0, 800.0, 10.0, "suffix:px") var lose_target_range: float = 300.0
## Intervalo entre varreduras de percepção/raycast de visão enquanto o inimigo está em Patrulha.
@export_range(0.05, 0.5, 0.01, "suffix:s") var patrol_scan_interval: float = 0.12

@export_group("Attack Balancing")
@export_range(5.0, 100.0, 1.0) var normal_damage: float = 14.0
@export_range(10.0, 150.0, 1.0) var heavy_damage: float = 22.0
@export_range(15.0, 200.0, 1.0) var perilous_damage: float = 34.0
@export_range(0.1, 1.5, 0.05, "suffix:s") var telegraph_duration: float = 0.45
## Multiplicador da duração do telegraph no ataque Branco (Normal).
@export_range(0.2, 3.0, 0.05) var normal_telegraph_mult: float = 0.85
## Multiplicador da duração do telegraph no ataque Amarelo (Pesado).
@export_range(0.2, 3.0, 0.05) var heavy_telegraph_mult: float = 1.00
## Multiplicador da duração do telegraph no ataque Vermelho (Perilous).
@export_range(0.2, 3.0, 0.05) var perilous_telegraph_mult: float = 1.05
## Tempo padrão de stagger deste inimigo ao receber um golpe normal.
@export_range(0.05, 1.5, 0.02, "suffix:s") var hurt_stun_duration: float = 0.22
## Tempo de espera na borda/parede antes de inverter a direção na patrulha.
@export_range(0.1, 3.0, 0.05, "suffix:s") var patrol_wait_duration: float = 0.5
@export_range(0.0, 20.0, 0.05, "suffix:s") var attack_cooldown: float = 2.0
@export_range(0.1, 1.0, 0.05) var cooldown_speed_mult: float = 0.48
@export_range(0.5, 8.0, 0.25, "suffix:s") var lose_aggro_time: float = 2.5
@export_range(0.5, 5.0, 0.25, "suffix:s") var reaggro_cooldown_duration: float = 1.5

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
@export var tier_3_has_hyper_armor: bool = false
@export var tier_3_can_be_elite: bool = true
@export_range(0.0, 1.0, 0.05) var tier_3_elite_chance: float = 0.25

@export_group("Respawn (Test Mode)")
@export var respawn_enabled: bool = false
@export_range(1.0, 30.0, 0.5, "suffix:s") var respawn_delay: float = 4.0

@export_group("Death & VFX")
## Duração da dissolução em pixels ao morrer.
@export_range(0.2, 1.5, 0.05, "suffix:s") var death_dissolve_duration: float = 0.55
## Cor da borda incandescente da dissolução (padrão: esmeralda espectral; Elites usam brasa carmesim).
@export var death_burn_color: Color = Color(0.35, 0.92, 0.68, 1.0)
@export var elite_death_burn_color: Color = Color(1.0, 0.38, 0.18, 1.0)

var spawn_position: Vector2 = Vector2.ZERO
var base_max_health: float = 60.0
var current_health: float = 60.0
var facing_direction: int = -1
var target_player: Player = null
var is_hyper_armored: bool = false
var current_attack_type: Hitbox.AttackCategory = Hitbox.AttackCategory.NORMAL
var attack_cycle_index: int = 0
var reaggro_cooldown: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial
var _cached_player: Player = null
var _patrol_scan_timer: float = 0.0

static var _shared_dissolve_noise: NoiseTexture2D = null


static func _get_shared_dissolve_noise() -> NoiseTexture2D:
	if _shared_dissolve_noise == null:
		var fnl := FastNoiseLite.new()
		fnl.noise_type = FastNoiseLite.TYPE_CELLULAR
		fnl.frequency = 0.14
		fnl.fractal_octaves = 2
		var ntex := NoiseTexture2D.new()
		ntex.width = 64
		ntex.height = 64
		ntex.seamless = true
		ntex.noise = fnl
		_shared_dissolve_noise = ntex
	return _shared_dissolve_noise

# Active Tier State
var active_tier: int = 1
var allowed_attacks_mask: int = 1
var active_behavior: CooldownBehavior = CooldownBehavior.AGGRESSIVE_STALK
var active_damage_multiplier: float = 1.0
var is_elite_active: bool = false
var is_adaptive_evading: bool = false
var adaptive_evade_timer: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var body_polygon: Polygon2D = get_node_or_null("Visual/Body") as Polygon2D
@onready var telegraph_mark: Node2D = get_node_or_null("Visual/TelegraphMark") as Node2D
@onready var white_mark: Polygon2D = get_node_or_null("Visual/TelegraphMark/WhiteMark") as Polygon2D
@onready var yellow_mark: Polygon2D = get_node_or_null("Visual/TelegraphMark/YellowMark") as Polygon2D
@onready var red_mark: Polygon2D = get_node_or_null("Visual/TelegraphMark/RedMark") as Polygon2D
@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox") as Hurtbox
@onready var state_machine: StateMachine = get_node_or_null("StateMachine") as StateMachine


func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	base_max_health = max_health
	_patrol_scan_timer = randf_range(0.0, patrol_scan_interval)
	if initial_facing != 0:
		facing_direction = initial_facing
	apply_tier_by_level(1)
	update_facing(float(facing_direction), true)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	hide_telegraph()

	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	var flash_target := _get_flash_target()
	if shader and flash_target:
		flash_material = ShaderMaterial.new()
		flash_material.shader = shader
		flash_material.set_shader_parameter("flash_active", false)
		flash_material.set_shader_parameter("dissolve_amount", 0.0)
		flash_material.set_shader_parameter("noise_texture", _get_shared_dissolve_noise())
		flash_material.set_shader_parameter("burn_color", elite_death_burn_color if is_elite_active else death_burn_color)
		flash_target.material = flash_material
		if flash_target == visual:
			_propagate_parent_material_to_visuals(visual)

	_on_enemy_ready()


func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

	if is_adaptive_evading:
		adaptive_evade_timer -= delta
		if adaptive_evade_timer <= 0.0:
			is_adaptive_evading = false

	var is_dead_state: bool = state_machine != null and state_machine.current_state is EnemyDeathState
	if visual and not is_dead_state:
		visual.scale.y = move_toward(visual.scale.y, get_visual_scale_magnitude(), 4.0 * delta)

	_on_enemy_physics_process(delta)


func get_visual_scale_magnitude() -> float:
	return 1.15 if is_elite_active else 1.0


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

	max_health = base_max_health * hp_mult
	current_health = max_health

	if body_polygon:
		body_polygon.color = _get_tier_body_color()
	if visual:
		var mag: float = get_visual_scale_magnitude()
		visual.scale = Vector2(float(facing_direction) * mag, mag)
	set_dissolve_amount(0.0)
	if flash_material:
		flash_material.set_shader_parameter("flash_active", false)


func update_facing(direction: float, force_sync: bool = false) -> void:
	var new_facing: int = 0
	if direction > 0.0:
		new_facing = 1
	elif direction < 0.0:
		new_facing = -1

	if new_facing == 0:
		return

	var mag: float = get_visual_scale_magnitude()
	var target_scale_x: float = float(new_facing) * mag
	if force_sync or new_facing != facing_direction or (visual and not is_equal_approx(visual.scale.x, target_scale_x)):
		facing_direction = new_facing
		if visual:
			visual.scale.x = target_scale_x


# --- Stateless Spatial Sensors (PhysicsServer Layer 1: Solid World Environment) ---

func is_at_ledge(dir: int, edge_offset: float = 14.0) -> bool:
	var space := get_world_2d().direct_space_state
	if not space:
		return true
	var check_x: float = global_position.x + float(dir) * edge_offset
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(check_x, global_position.y - 2.0),
		Vector2(check_x, global_position.y + 16.0),
		1
	)
	return space.intersect_ray(query).is_empty()


func is_hitting_wall(dir: int, wall_dist: float = 14.0) -> bool:
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -16.0),
		global_position + Vector2(float(dir) * wall_dist, -16.0),
		1
	)
	return not space.intersect_ray(query).is_empty()


func can_step_in_direction(dir: int, edge_offset: float = 14.0) -> bool:
	if not is_on_floor():
		return false
	return not is_at_ledge(dir, edge_offset) and not is_hitting_wall(dir, edge_offset)


func can_step_forward(edge_offset: float = 14.0) -> bool:
	return can_step_in_direction(facing_direction, edge_offset)


func can_step_backward(edge_offset: float = 14.0) -> bool:
	return can_step_in_direction(-facing_direction, edge_offset)


func has_line_of_sight_to(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -20.0),
		target.global_position + Vector2(0.0, -20.0),
		1
	)
	return space.intersect_ray(query).is_empty()


func find_player() -> Player:
	if target_player and is_instance_valid(target_player):
		return target_player
	if _cached_player and is_instance_valid(_cached_player) and _cached_player.is_inside_tree():
		return _cached_player
	var tree := get_tree()
	if not tree:
		return null
	var players := tree.get_nodes_in_group(&"player")
	if players.size() > 0 and players[0] is Player:
		_cached_player = players[0] as Player
		return _cached_player
	if tree.current_scene:
		var p := tree.current_scene.find_child("Player", true, false)
		if p is Player:
			_cached_player = p as Player
			return _cached_player
	return null


func should_run_patrol_scan(delta: float) -> bool:
	if reaggro_cooldown > 0.0:
		reaggro_cooldown = maxf(0.0, reaggro_cooldown - delta)
		return false
	_patrol_scan_timer -= delta
	if _patrol_scan_timer <= 0.0:
		_patrol_scan_timer = patrol_scan_interval
		return true
	return false


# --- Telegraph & Attack Cycle ---

func advance_attack_cycle() -> Hitbox.AttackCategory:
	var pool: Array[Hitbox.AttackCategory] = []
	if (allowed_attacks_mask & 1) != 0:
		pool.append(Hitbox.AttackCategory.NORMAL)
	if (allowed_attacks_mask & 2) != 0:
		pool.append(Hitbox.AttackCategory.HEAVY)
	if (allowed_attacks_mask & 4) != 0:
		pool.append(Hitbox.AttackCategory.PERILOUS)
	if pool.is_empty():
		pool.append(Hitbox.AttackCategory.NORMAL)

	var chosen: Hitbox.AttackCategory = pool[attack_cycle_index % pool.size()]
	attack_cycle_index += 1
	current_attack_type = chosen
	return chosen


func show_telegraph(type: Hitbox.AttackCategory) -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if white_mark:
		white_mark.visible = (type == Hitbox.AttackCategory.NORMAL)
	if yellow_mark:
		yellow_mark.visible = (type == Hitbox.AttackCategory.HEAVY)
	if red_mark:
		red_mark.visible = (type == Hitbox.AttackCategory.PERILOUS)


func show_white_telegraph() -> void:
	show_telegraph(Hitbox.AttackCategory.NORMAL)


func show_yellow_telegraph() -> void:
	show_telegraph(Hitbox.AttackCategory.HEAVY)


func show_red_telegraph() -> void:
	show_telegraph(Hitbox.AttackCategory.PERILOUS)


func hide_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = false
	if white_mark:
		white_mark.visible = false
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = false


# --- Combat Feedback, Parry Stun & Respawn ---

func trigger_hit_flash(duration: float = 0.08) -> void:
	flash_timer = duration
	if flash_material:
		flash_material.set_shader_parameter("flash_active", true)


func _propagate_parent_material_to_visuals(node: Node) -> void:
	for child in node.get_children():
		var child_name: String = String(child.name)
		if child_name == "TelegraphMark" or child_name.begins_with("Hitbox") or child_name.begins_with("SlashArc"):
			continue
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = true
		_propagate_parent_material_to_visuals(child)


func set_dissolve_amount(amount: float) -> void:
	if flash_material:
		flash_material.set_shader_parameter("burn_color", elite_death_burn_color if is_elite_active else death_burn_color)
		flash_material.set_shader_parameter("dissolve_amount", clampf(amount, 0.0, 1.0))


func on_attack_blocked(is_parry: bool) -> void:
	if active_behavior == CooldownBehavior.ADAPTIVE and can_move:
		is_adaptive_evading = true
		adaptive_evade_timer = 1.2 if is_parry else 0.8


func apply_parry_stun(duration: float = 0.85) -> void:
	is_hyper_armored = false
	hide_telegraph()
	_on_parry_stun_applied(duration)
	trigger_hit_flash(0.25)

	if visual:
		visual.scale.y = 0.7 * get_visual_scale_magnitude()
	velocity = Vector2.ZERO

	if state_machine:
		var hurt_state := state_machine.get_node_or_null("Hurt")
		if hurt_state and "custom_stun_duration" in hurt_state:
			hurt_state.custom_stun_duration = duration
		state_machine.transition_to("hurt")


func drop_aggro() -> void:
	target_player = null
	reaggro_cooldown = reaggro_cooldown_duration
	hide_telegraph()
	if state_machine:
		state_machine.transition_to("patrol")


func respawn() -> void:
	global_position = spawn_position
	current_health = max_health
	velocity = Vector2.ZERO
	target_player = null
	reaggro_cooldown = 0.0
	_patrol_scan_timer = 0.0
	is_adaptive_evading = false
	is_hyper_armored = false
	hide_telegraph()
	visible = true

	var mag: float = get_visual_scale_magnitude()
	if visual:
		visual.visible = true
		visual.modulate = Color.WHITE
		visual.scale = Vector2(float(facing_direction) * mag, mag)
	set_dissolve_amount(0.0)
	if flash_material:
		flash_material.set_shader_parameter("flash_active", false)

	set_collision_layer_value(3, true)
	var body_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_col:
		body_col.set_deferred("disabled", false)
	if hurtbox:
		hurtbox.is_invulnerable = false
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
		if hurtbox.has_node("CollisionShape2D"):
			hurtbox.get_node("CollisionShape2D").set_deferred("disabled", false)

	_on_enemy_respawn()
	var reset_dir: int = initial_facing if initial_facing != 0 else facing_direction
	update_facing(float(reset_dir), true)
	if state_machine:
		state_machine.transition_to("patrol")


# --- Virtual Hooks for Subclasses ---

func _get_flash_target() -> CanvasItem:
	return visual if visual else body_polygon


func _get_tier_body_color() -> Color:
	if is_elite_active:
		return Color(0.85, 0.2, 0.2, 1.0)
	if active_tier == 3:
		return Color(0.55, 0.25, 0.45, 1.0)
	if active_tier == 2:
		return Color(0.35, 0.45, 0.6, 1.0)
	return Color(0.3, 0.35, 0.4, 1.0)


func _on_enemy_ready() -> void:
	pass


func _on_enemy_physics_process(_delta: float) -> void:
	pass


func _on_hit_received(_amount: float, _knockback: Vector2, _hitstop: float) -> void:
	pass


func _on_parry_stun_applied(_duration: float) -> void:
	pass


func _on_death_enter() -> void:
	pass


func _on_enemy_respawn() -> void:
	pass
