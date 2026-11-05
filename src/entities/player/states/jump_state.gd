class_name JumpState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.velocity.y = player.jump_velocity
	player.last_wall_jump_normal_x = 0.0
	player.is_wall_recovery_active = false
	player.fall_peak_y = player.global_position.y

func physics_update(delta: float) -> void:
	# Wall jump check: kick off wall if pressing jump while touching wall in air
	if Input.is_action_just_pressed("jump") and player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			state_machine.transition_to("walljump")
			return

	# Double jump check
	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	# Roll in air
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	# Attack in air
	if Input.is_action_just_pressed("attack_primary"):
		state_machine.transition_to("attack")
		return

	# Air horizontal control
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, (player.run_speed / 0.15) * delta)

	player.velocity.y += player.gravity * delta
	player.fall_peak_y = minf(player.fall_peak_y, player.global_position.y)

	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")
		return

	# Ledge climb check while rising towards corner
	var is_holding_away: bool = (direction != 0.0 and signf(direction) != float(player.facing_direction))
	if not is_holding_away:
		if player.check_ledge():
			state_machine.transition_to("ledgeclimb")
			return

	player.move_and_slide()
