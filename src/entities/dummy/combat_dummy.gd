class_name CombatDummy
extends CharacterBody2D

## Responsive training target to calibrate combat feedback, hitstop, and knockback.

@export_group("Target Stats")
@export_range(1.0, 5000.0, 10.0, "or_greater") var max_health: float = 1000.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var friction: float = 800.0

var current_health: float = 1000.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body

var flash_material: ShaderMaterial

func _ready() -> void:
	current_health = max_health
	hurtbox.hit_received.connect(_on_hit_received)
	
	# Instantiate unique shader material for hit flash
	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	flash_material = ShaderMaterial.new()
	flash_material.shader = shader
	body_polygon.material = flash_material

func _physics_process(delta: float) -> void:
	# Gravity & friction
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	
	move_and_slide()
	
	# Handle hit flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flash_material.set_shader_parameter("flash_active", false)
	
	# Smooth squash & stretch recovery
	visual.scale = visual.scale.move_toward(Vector2.ONE, 6.0 * delta)

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	current_health -= damage
	velocity = knockback
	
	# Visual juice: Hit flash pure white
	flash_timer = hitstop + 0.05
	flash_material.set_shader_parameter("flash_active", true)
	
	# Visual juice: Squash & Stretch
	visual.scale = Vector2(1.3, 0.75)
