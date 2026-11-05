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
			return
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			state_machine.transition_to("run")
			return
		else:
			state_machine.transition_to("idle")
			return

	if player.coyote_timer > 0.0 and Input.is_action_just_pressed("jump"):
		player.coyote_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Wall jump check while touching wall (takes precedence over double jump)
	if (Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0) and player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			player.jump_buffer_timer = 0.0
			state_machine.transition_to("walljump")
			return

	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	# Attack in air
	if Input.is_action_just_pressed("attack_primary") and player.can_attack():
		state_machine.transition_to("attack")
		return

	# Horizontal air control (update facing first)
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)

	# Ledge climb check: mantle onto platform corner if touching or moving towards ledge
	var is_holding_away: bool = (direction != 0.0 and signf(direction) != float(player.facing_direction))
	if not is_holding_away:
		if player.check_ledge():
			state_machine.transition_to("ledgeclimb")
			return

	if player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			if signf(direction) == -wall_norm:
				state_machine.transition_to("wallslide")
				return

	# Gravity (100% normal, falls cleanly through enemies)
	player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta

	if direction != 0.0:
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.run_speed,
			(player.run_speed / player.acceleration_time) * delta
		)
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			(player.run_speed / player.acceleration_time) * delta
		)

	player.move_and_slide()
