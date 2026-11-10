class_name CrouchState
extends State

## Crouch / Duck State when pressing down.
## Decreases player hitbox height to 20px (under 32px gaps) and prevents walking through solid enemies.

var player: Player

func enter() -> void:
	player = character as Player
	player.velocity.x = 0.0
	player.play_animation(&"crouch")
	player.set_crouched(true)

func exit() -> void:
	player.set_crouched(false)
	player.stop_animation()

func physics_update(delta: float) -> void:
	if player.is_input_locked:
		state_machine.transition_to("idle")
		return

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	# Roll from crouch
	if player.is_roll_requested():
		state_machine.transition_to("roll")
		return

	# Heal check (Garrafa de Chá da Mãe)
	if Input.is_action_just_pressed("heal"):
		state_machine.transition_to("heal")
		return

	# Jump from crouch
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Attack from crouch (supports holding button)
	if Input.is_action_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	# Guard / Parry from crouch
	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	# Decelerate any remaining residual velocity
	player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
	player.move_and_slide()

	# If release down, check ceiling clearance before uncrouching
	var is_holding_down: bool = player.is_crouch_requested()
	if not is_holding_down:
		player.ceiling_check.force_raycast_update()
		if not player.ceiling_check.is_colliding():
			var h_dir: float = Input.get_axis("move_left", "move_right")
			if abs(h_dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
