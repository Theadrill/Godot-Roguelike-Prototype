class_name GameCamera
extends Camera2D

## Camera look-ahead controller:
## When using the right analog stick, shifts the camera offset smoothly in that direction to peek ahead.
## When released, smoothly lerps back to the centered default offset.

@export_group("Look-Ahead Metrics")
## Maximum horizontal pan distance when tilting right stick fully (pixels)
@export_range(20.0, 250.0, 5.0, "suffix:px") var max_pan_distance_x: float = 96.0
## Maximum vertical pan distance when tilting right stick fully (pixels)
@export_range(10.0, 180.0, 5.0, "suffix:px") var max_pan_distance_y: float = 54.0
## Smoothing speed when panning towards look direction (lower = heavier and slower)
@export_range(0.5, 10.0, 0.1) var pan_speed: float = 2.0
## Smoothing speed when returning to default center (lower = heavier and slower)
@export_range(0.5, 10.0, 0.1) var return_speed: float = 3.2
## Deadzone to ignore small resting stick jitter
@export_range(0.05, 0.5, 0.05) var deadzone: float = 0.20

var base_offset: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO

var trauma: float = 0.0
@export var max_shake_offset: Vector2 = Vector2(5.0, 4.0)
@export var trauma_decay: float = 0.8

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _ready() -> void:
	base_offset = offset

func _physics_process(delta: float) -> void:
	# Read right stick vector
	var look_dir := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if look_dir.length() > deadzone:
		# Player is holding right stick to peek
		target_offset = base_offset + Vector2(
			look_dir.x * max_pan_distance_x,
			look_dir.y * max_pan_distance_y
		)
		offset = offset.lerp(target_offset, pan_speed * delta)
	else:
		# Released: smoothly glide back to default base offset
		target_offset = base_offset
		offset = offset.lerp(target_offset, return_speed * delta)

	# Trauma-based subtle screen shake decay
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - trauma_decay * delta)
		var shake := Vector2(
			randf_range(-1.0, 1.0) * max_shake_offset.x * (trauma * trauma),
			randf_range(-1.0, 1.0) * max_shake_offset.y * (trauma * trauma)
		)
		offset += shake
