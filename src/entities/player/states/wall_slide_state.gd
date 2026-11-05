class_name WallSlideState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.can_double_jump = true # Reset double jump on touching wall

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	if not player.is_on_wall_only():
		state_machine.transition_to("fall")
		return

	# Wall jump check
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("walljump")
		return

	# Sliding down with clamped speed
	player.velocity.y = move_toward(player.velocity.y, player.wall_slide_speed, (player.gravity * 0.5) * delta)
	player.move_and_slide()
