class_name Player
extends CharacterBody2D

## Player controller implementing the physics metrics and state management.

@export_group("Attributes & Stats")
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_health: float = 100.0
@export_range(0.0, 500.0, 1.0, "or_greater") var max_mana: float = 100.0
var current_health: float = 100.0
var current_mana: float = 100.0

@export_group("Horizontal Movement")
@export_range(50.0, 600.0, 10.0, "suffix:px/s") var run_speed: float = 220.0
@export_range(0.01, 0.5, 0.01, "suffix:s") var acceleration_time: float = 0.08

@export_group("Jumping & Gravity")
@export_range(-800.0, -100.0, 10.0, "suffix:px/s") var jump_velocity: float = -354.0        # Exact 4 tiles (64 px)
@export_range(-800.0, -100.0, 10.0, "suffix:px/s") var double_jump_velocity: float = -306.0 # Exact +3 tiles (48 px)
@export_range(0.5, 3.0, 0.05) var fall_gravity_multiplier: float = 1.35                     # Snappy fall (Dead Cells)
@export_range(0.0, 0.3, 0.01, "suffix:s") var coyote_duration: float = 0.12
@export_range(0.0, 0.3, 0.01, "suffix:s") var jump_buffer_duration: float = 0.12

@export_group("Wall Mechanics")
@export_range(10.0, 300.0, 5.0, "suffix:px/s") var wall_slide_speed: float = 70.0
@export_range(50.0, 500.0, 10.0, "suffix:px/s") var wall_jump_horizontal: float = 240.0
@export_range(-600.0, -100.0, 10.0, "suffix:px/s") var wall_jump_vertical: float = -330.0

@export_group("Roll & Dodge")
@export_range(100.0, 800.0, 10.0, "suffix:px/s") var roll_speed: float = 240.0
@export_range(0.1, 1.0, 0.01, "suffix:s") var roll_duration: float = 0.28

@export_group("Combat & Equipment")
@export var weapon: WeaponData

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = false
var facing_direction: int = 1

# Wall jump tracking: prevents infinite climbing on the same single wall
var last_wall_jump_normal_x: float = 0.0

# Default gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial
var enemy_head_stuck_timer: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/BodyPlaceholder
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var slash_effect: Node2D = $Visual/SlashEffect

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	if not weapon:
		weapon = WeaponData.new()

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

func set_slash_visual(is_active: bool, combo_step: int = 0, is_upward: bool = false) -> void:
	if slash_effect:
		slash_effect.visible = is_active
		if is_active:
			if is_upward:
				slash_effect.position = Vector2(0.0, -32.0)
				slash_effect.rotation_degrees = -90.0
				slash_effect.scale = Vector2(1.2, 1.2)
			else:
				slash_effect.position = Vector2(0.0, -20.0)
				slash_effect.rotation_degrees = -20.0 if combo_step == 0 else (20.0 if combo_step == 1 else 0.0)
				slash_effect.scale = Vector2(1.0 + combo_step * 0.2, 1.0 + combo_step * 0.2)

func _physics_process(delta: float) -> void:
	var on_enemy: bool = is_standing_on_enemy()
	if on_enemy:
		enemy_head_stuck_timer += delta
	else:
		enemy_head_stuck_timer = 0.0

	# Decrement timers
	if is_on_floor():
		if on_enemy:
			# Standing on enemy head: prevent coyote time and slide off
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			_prevent_standing_on_enemies()
		else:
			coyote_timer = coyote_duration
			can_double_jump = true
			last_wall_jump_normal_x = 0.0 # Reset wall memory on ground touch
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# Strictly prevent buffering or triggering jumps when touching an enemy head
	if Input.is_action_just_pressed("jump"):
		if not on_enemy:
			jump_buffer_timer = jump_buffer_duration
		else:
			jump_buffer_timer = 0.0

	# Hit flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	current_health = max(0.0, current_health - damage)
	velocity = knockback

	# Visual juice: Hit flash pure white
	if flash_material:
		flash_timer = hitstop + 0.08
		flash_material.set_shader_parameter("flash_active", true)

	# Tactile juice: Gamepad rumble & hitstop
	CombatFeedback.apply_hit_feedback(hitstop, 0.4, 0.7, 0.12)

func is_standing_on_enemy() -> bool:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is CombatDummy or collider is Soldier or (collider is CollisionObject2D and collider.get_collision_layer_value(3)):
			if col.get_normal().y < -0.5:
				return true
	return false

func _prevent_standing_on_enemies() -> void:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		# If the collider is on Enemy layer (Layer 3) or is an enemy/dummy
		if collider is CombatDummy or collider is Soldier or (collider is CollisionObject2D and collider.get_collision_layer_value(3)):
			# Normal pointing up means player landed directly on their top head/shoulders
			if col.get_normal().y < -0.5:
				var push_dir: float = signf(global_position.x - collider.global_position.x)
				if push_dir == 0.0:
					push_dir = float(facing_direction)

				# Raycast wall awareness (Layer 1: Environment):
				# Check if sliding in push_dir would hit a wall within 24px
				var space := get_world_2d().direct_space_state
				if space:
					var ray_origin := global_position + Vector2(0.0, -10.0)
					var ray_r := PhysicsRayQueryParameters2D.create(ray_origin, ray_origin + Vector2(24.0, 0.0), 1)
					ray_r.exclude = [get_rid()]
					var wall_on_right: bool = not space.intersect_ray(ray_r).is_empty()

					var ray_l := PhysicsRayQueryParameters2D.create(ray_origin, ray_origin + Vector2(-24.0, 0.0), 1)
					ray_l.exclude = [get_rid()]
					var wall_on_left: bool = not space.intersect_ray(ray_l).is_empty()

					# Steer away from walls!
					if push_dir > 0.0 and wall_on_right and not wall_on_left:
						push_dir = -1.0
					elif push_dir < 0.0 and wall_on_left and not wall_on_right:
						push_dir = 1.0

				# Layer 3: Timeout Fail-safe (eject strongly if wedged for > 0.2s)
				if enemy_head_stuck_timer > 0.2:
					velocity.y = -120.0
					velocity.x = push_dir * 260.0
					global_position.x += push_dir * 4.0
				else:
					velocity.x = push_dir * 220.0
					global_position.x += push_dir * 2.0

				coyote_timer = 0.0
				jump_buffer_timer = 0.0
				return

func update_facing(direction: float) -> void:
	if direction > 0.0:
		facing_direction = 1
		visual.scale.x = 1.0
	elif direction < 0.0:
		facing_direction = -1
		visual.scale.x = -1.0
