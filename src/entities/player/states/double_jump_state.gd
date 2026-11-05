class_name DoubleJumpState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.can_double_jump = false
	player.velocity.y = player.double_jump_velocity

func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	if player.is_on_wall_only() and Input.is_action_pressed("move_left" if player.facing_direction == -1 else "move_right"):
		state_machine.transition_to("wallslide")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, (player.run_speed / 0.15) * delta)

	player.velocity.y += player.gravity * delta

	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")
		return

	player.move_and_slide()
