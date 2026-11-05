class_name FallState
extends State

var player: Player

func enter() -> void:
	player = character as Player

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		if player.jump_buffer_timer > 0.0:
			player.jump_buffer_timer = 0.0
			state_machine.transition_to("jump")
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return

	if player.coyote_timer > 0.0 and Input.is_action_just_pressed("jump"):
		player.coyote_timer = 0.0
		state_machine.transition_to("jump")
		return

	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	if player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			var move_dir: float = Input.get_axis("move_left", "move_right")
			if signf(move_dir) == -wall_norm:
				state_machine.transition_to("wallslide")
				return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, (player.run_speed / 0.15) * delta)

	player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta
	player.velocity.y = min(player.velocity.y, 650.0)

	player.move_and_slide()
