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

@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var slash_effect: Node2D = $Visual/SlashEffect

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	if not weapon:
		weapon = WeaponData.new()

func set_slash_visual(is_active: bool, combo_step: int = 0) -> void:
	if slash_effect:
		slash_effect.visible = is_active
		if is_active:
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

func update_facing(direction: float) -> void:
	if direction > 0.0:
		facing_direction = 1
		visual.scale.x = 1.0
	elif direction < 0.0:
		facing_direction = -1
		visual.scale.x = -1.0
