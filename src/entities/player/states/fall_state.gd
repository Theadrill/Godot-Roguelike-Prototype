class_name FallState
extends State

var player: Player

func enter() -> void:
	player = character as Player

func physics_update(delta: float) -> void:
	# Landed on floor
	if player.is_on_floor():
		if player.jump_buffer_timer > 0.0:
			player.jump_buffer_timer = 0.0
			state_machine.transition_to("jump")
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return

	# Coyote jump check (fell off ledge without jumping)
	if player.coyote_timer > 0.0 and Input.is_action_just_pressed("jump"):
		player.coyote_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Double jump check in midair
	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	# Roll in air
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

	# Snappy fall gravity (1.35x)
	player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta
	player.velocity.y = min(player.velocity.y, 650.0) # Terminal velocity

	player.move_and_slide()
