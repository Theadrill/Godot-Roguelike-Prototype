class_name Player
extends CharacterBody2D

## Player controller implementing the physics metrics and state management.

# Movement constants calibrated to 16px grid
@export var run_speed: float = 220.0
@export var acceleration_time: float = 0.08
@export var jump_velocity: float = -354.0        # Exact 4 tiles (64 px) height
@export var double_jump_velocity: float = -306.0 # Exact +3 tiles (48 px) height
@export var fall_gravity_multiplier: float = 1.35 # Snappy fall feel (Dead Cells)
@export var wall_slide_speed: float = 70.0
@export var wall_jump_horizontal: float = 200.0
@export var wall_jump_vertical: float = -320.0
@export var roll_speed: float = 340.0
@export var roll_duration: float = 0.35

# Coyote Time & Jump Buffering (Pillars of Game Feel)
@export var coyote_duration: float = 0.12
@export var jump_buffer_duration: float = 0.12

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = false
var facing_direction: int = 1

# Default gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var ceiling_check: RayCast2D = $CeilingCheck

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Decrement timers
	if is_on_floor():
		coyote_timer = coyote_duration
		can_double_jump = true
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
