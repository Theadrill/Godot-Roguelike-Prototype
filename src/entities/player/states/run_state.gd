class_name RunState
extends State

var player: Player

func enter() -> void:
	player = character as Player

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	if player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if abs(direction) < 0.1:
		state_machine.transition_to("idle")
		return

	player.update_facing(direction)
	# Fast acceleration (0.08s)
	var target_speed := direction * player.run_speed
	var accel_rate := player.run_speed / player.acceleration_time
	player.velocity.x = move_toward(player.velocity.x, target_speed, accel_rate * delta)

	player.move_and_slide()
