class_name Archer
extends CharacterBody2D

## Ranged Archer Enemy:
## Implements tactical kiting (retreats if player gets too close),
## 3-signal telegraph aiming, and fires physical arrows that can be deflected via Parry.

@export_group("Base Stats")
@export var can_move: bool = true
@export var takes_knockback: bool = true
@export var stationary: bool = false:
	set(val):
		stationary = val
		can_move = not val
@export_range(-1, 1, 2) var initial_facing: int = -1
@export_range(10.0, 500.0, 5.0) var max_health: float = 45.0
@export_range(10.0, 200.0, 5.0, "suffix:px/s") var patrol_speed: float = 35.0
@export_range(30.0, 300.0, 5.0, "suffix:px/s") var kite_speed: float = 75.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var friction: float = 800.0

@export_group("Perception & Range")
@export_range(50.0, 600.0, 10.0, "suffix:px") var spot_range: float = 340.0
@export_range(30.0, 300.0, 5.0, "suffix:px") var back_awareness_range: float = 140.0
@export_range(30.0, 200.0, 5.0, "suffix:px") var attack_range: float = 95.0
@export_range(100.0, 800.0, 10.0, "suffix:px") var lose_target_range: float = 420.0
var min_kite_distance: float:
	get: return attack_range
	set(val): attack_range = val

@export_group("Attack Balancing")
@export_range(5.0, 80.0, 1.0) var normal_damage: float = 16.0
@export_range(10.0, 120.0, 1.0) var heavy_damage: float = 24.0
@export_range(15.0, 160.0, 1.0) var perilous_damage: float = 35.0
@export_range(200.0, 1200.0, 50.0, "suffix:px/s") var arrow_speed: float = 520.0
@export_range(0.1, 1.5, 0.05, "suffix:s") var telegraph_duration: float = 0.50
@export_range(0.0, 20.0, 0.05, "suffix:s") var attack_cooldown: float = 0.60
var shoot_cooldown: float:
	get: return attack_cooldown
	set(val): attack_cooldown = val

@export_group("Respawn (Test Mode)")
@export var respawn_enabled: bool = true
@export_range(1.0, 30.0, 0.5, "suffix:s") var respawn_delay: float = 4.0

var spawn_position: Vector2 = Vector2.ZERO
var current_health: float = 45.0
var facing_direction: int = -1
var target_player: Player = null
var current_attack_type: Hitbox.AttackCategory = Hitbox.AttackCategory.NORMAL
var attack_cycle_index: int = 0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var bow_node: Node2D = $Visual/Bow
@onready var arrow_spawn_marker: Marker2D = $Visual/Bow/ArrowSpawn
@onready var telegraph_mark: Node2D = $Visual/TelegraphMark
@onready var white_mark: Polygon2D = $Visual/TelegraphMark/WhiteMark
@onready var yellow_mark: Polygon2D = $Visual/TelegraphMark/YellowMark
@onready var red_mark: Polygon2D = $Visual/TelegraphMark/RedMark
@onready var wall_check: RayCast2D = $WallCheck
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var back_wall_check: RayCast2D = $BackWallCheck
@onready var back_ledge_check: RayCast2D = $BackLedgeCheck
@onready var sight_ray: RayCast2D = $SightRay
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	spawn_position = global_position
	current_health = max_health
	if initial_facing != 0:
		update_facing(float(initial_facing))
	hurtbox.hit_received.connect(_on_hit_received)
	hide_telegraph()

	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	if shader:
		flash_material = ShaderMaterial.new()
		flash_material.shader = shader
		flash_material.set_shader_parameter("flash_active", false)
		visual.material = flash_material

func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

func update_facing(direction: float) -> void:
	var new_facing: int = 0
	if direction > 0.0:
		new_facing = 1
	elif direction < 0.0:
		new_facing = -1

	if new_facing != 0 and (new_facing != facing_direction or visual.scale.x != float(new_facing)):
		facing_direction = new_facing
		visual.scale.x = float(facing_direction)

		# Sync raycasts direction
		wall_check.target_position.x = absf(wall_check.target_position.x) * float(facing_direction)
		ledge_check.position.x = absf(ledge_check.position.x) * float(facing_direction)
		back_wall_check.target_position.x = -absf(back_wall_check.target_position.x) * float(facing_direction)
		back_ledge_check.position.x = -absf(back_ledge_check.position.x) * float(facing_direction)

func can_step_forward() -> bool:
	if not is_on_floor():
		return false
	if wall_check.is_colliding():
		return false
	if not ledge_check.is_colliding():
		return false
	return true

func can_step_backward() -> bool:
	if not is_on_floor():
		return false
	if back_wall_check.is_colliding():
		return false
	if not back_ledge_check.is_colliding():
		return false
	return true

func has_line_of_sight_to(player: Player) -> bool:
	if not is_instance_valid(player):
		return false
	var space := get_world_2d().direct_space_state
	if not space:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -20.0),
		player.global_position + Vector2(0.0, -20.0),
		1 # Layer 1: Solid world environment
	)
	var hit := space.intersect_ray(query)
	return hit.is_empty()

func advance_attack_cycle() -> Hitbox.AttackCategory:
	# 1:1:1 balanced distribution: White (Normal) -> Yellow (Heavy) -> Red (Perilous)
	var chosen: Hitbox.AttackCategory
	match attack_cycle_index % 3:
		0:
			chosen = Hitbox.AttackCategory.NORMAL
		1:
			chosen = Hitbox.AttackCategory.HEAVY
		2:
			chosen = Hitbox.AttackCategory.PERILOUS
	attack_cycle_index += 1
	current_attack_type = chosen
	return chosen

func show_telegraph(type: Hitbox.AttackCategory) -> void:
	telegraph_mark.visible = true
	white_mark.visible = (type == Hitbox.AttackCategory.NORMAL)
	yellow_mark.visible = (type == Hitbox.AttackCategory.HEAVY)
	red_mark.visible = (type == Hitbox.AttackCategory.PERILOUS)

func hide_telegraph() -> void:
	telegraph_mark.visible = false
	white_mark.visible = false
	yellow_mark.visible = false
	red_mark.visible = false

func _on_hit_received(amount: float, knockback: Vector2, hitstop: float) -> void:
	if state_machine.current_state is ArcherDeathState:
		return

	current_health -= amount
	trigger_hit_flash()

	if not takes_knockback or not can_move:
		knockback = Vector2.ZERO

	if current_health <= 0.0:
		state_machine.transition_to("death")
	else:
		var hurt_state := state_machine.get_node_or_null("Hurt") as ArcherHurtState
		if hurt_state:
			hurt_state.incoming_knockback = knockback
			hurt_state.hitstop_time = hitstop
			state_machine.transition_to("hurt")

func trigger_hit_flash(duration: float = 0.08) -> void:
	flash_timer = duration
	if flash_material:
		flash_material.set_shader_parameter("flash_active", true)

func respawn() -> void:
	global_position = spawn_position
	current_health = max_health
	velocity = Vector2.ZERO
	target_player = null
	hide_telegraph()
	visible = true

	# Reset visual nodes, alpha, and squash
	if visual:
		visual.visible = true
		visual.modulate = Color.WHITE
		visual.scale.y = 1.0
	if bow_node:
		bow_node.rotation = 0.0

	# Reset collision & hurtbox
	set_collision_layer_value(3, true)
	$CollisionShape2D.set_deferred("disabled", false)
	if hurtbox:
		hurtbox.is_invulnerable = false
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
		if hurtbox.has_node("CollisionShape2D"):
			hurtbox.get_node("CollisionShape2D").set_deferred("disabled", false)

	update_facing(float(initial_facing))
	state_machine.transition_to("patrol")
