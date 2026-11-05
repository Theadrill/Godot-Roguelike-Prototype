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

@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/BodyPlaceholder
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var enemy_overlap_detector: Area2D = $EnemyOverlapDetector
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

func _physics_process(delta: float) -> void:
	# Decrement timers
	if is_on_floor():
		coyote_timer = coyote_duration
		can_double_jump = true
		last_wall_jump_normal_x = 0.0 # Reset wall memory on ground touch
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

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

func can_attack() -> bool:
	return attack_cooldown_timer <= 0.0

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	current_health = max(0.0, current_health - damage)
	velocity = knockback

	# Visual juice: Hit flash pure white
	if flash_material:
		flash_timer = hitstop + 0.08
		flash_material.set_shader_parameter("flash_active", true)

	# Tactile juice: Gamepad rumble & hitstop
	CombatFeedback.apply_hit_feedback(hitstop, 0.4, 0.7, 0.12)

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
	if direction > 0.0:
		facing_direction = 1
		visual.scale.x = 1.0
	elif direction < 0.0:
		facing_direction = -1
		visual.scale.x = -1.0

## Intent-filtered check for crouching.
## Prevents accidental crouches when tilting the analog stick diagonally while running.
func is_crouch_requested() -> bool:
	if not Input.is_action_pressed("down"):
		return false

	# Digital keys (Keyboard S / Arrow Down, Gamepad D-Pad Down) have 100% deliberate intent
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
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

	# Digital keys (Keyboard W / Arrow Up, Gamepad D-Pad Up)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
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
