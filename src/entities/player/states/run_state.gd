class_name RunState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.fall_peak_y = player.global_position.y

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	if player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Crouch check
	if player.is_crouch_requested():
		state_machine.transition_to("crouch")
		return

	# Heal check (Garrafa de Chá da Mãe)
	if Input.is_action_just_pressed("heal"):
		state_machine.transition_to("heal")
		return

	# Guard / Parry check
	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	# Attack check (supports holding button)
	if Input.is_action_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if abs(direction) < 0.1:
		state_machine.transition_to("idle")
		return

	player.update_facing(direction)
	# Fast acceleration (0.08s) with soft body enemy resistance (Dead Cells style)
	var speed_magnitude := player.run_speed
	if player.is_pushing_against_enemy(direction):
		speed_magnitude *= player.enemy_overlap_speed_multiplier

	var target_speed := direction * speed_magnitude
	var accel_rate := player.run_speed / player.acceleration_time
	player.velocity.x = move_toward(player.velocity.x, target_speed, accel_rate * delta)

	player.move_and_slide()
