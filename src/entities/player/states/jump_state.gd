class_name JumpState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.velocity.y = player.jump_velocity

func physics_update(delta: float) -> void:
	# Double jump check
	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	# Roll in air (optional or transition)
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	# Wall slide check
	if player.is_on_wall_only() and Input.is_action_pressed("move_left" if player.facing_direction == -1 else "move_right"):
		state_machine.transition_to("wallslide")
		return

	# Air horizontal control
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, (player.run_speed / 0.15) * delta)

	# Apply upward gravity
	player.velocity.y += player.gravity * delta

	# Apex / falling transition
	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")
		return

	player.move_and_slide()
