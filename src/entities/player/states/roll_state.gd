class_name RollState
extends State

var player: Player
var roll_timer: float = 0.0
var roll_direction: float = 1.0

func enter() -> void:
	player = character as Player
	roll_timer = player.roll_duration
	roll_direction = float(player.facing_direction)

	# Shrink collision height to 20px so player passes under low ceilings (32px)
	var rect := player.collision_shape.shape as RectangleShape2D
	if rect:
		rect.size = Vector2(16.0, 20.0)
		player.collision_shape.position = Vector2(0.0, -10.0)

	player.velocity.x = roll_direction * player.roll_speed
	# Maintain vertical physics if rolling in air / ledge
	if player.is_on_floor():
		player.velocity.y = 0.0

func exit() -> void:
	# Restore normal 16x40 collision shape
	var rect := player.collision_shape.shape as RectangleShape2D
	if rect:
		rect.size = Vector2(16.0, 40.0)
		player.collision_shape.position = Vector2(0.0, -20.0)

func physics_update(delta: float) -> void:
	roll_timer -= delta
	player.velocity.x = roll_direction * player.roll_speed

	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

	player.move_and_slide()

	if roll_timer <= 0.0:
		if player.is_on_floor():
			var dir := Input.get_axis("move_left", "move_right")
			if abs(dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
