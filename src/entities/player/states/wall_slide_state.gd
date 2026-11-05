class_name WallSlideState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.can_double_jump = true

	# Zero out upward velocity immediately so player sticks to the wall without sliding up
	if player.velocity.y < 0.0:
		player.velocity.y = 0.0

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	if not player.is_on_wall_only():
		state_machine.transition_to("fall")
		return

	# If player releases the directional towards the wall, let go
	var wall_dir := -player.get_wall_normal().x
	var input_dir := Input.get_axis("move_left", "move_right")
	if signf(input_dir) != signf(wall_dir):
		state_machine.transition_to("fall")
		return

	# Wall jump check
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("walljump")
		return

	# Sliding down with clamped speed
	player.velocity.y = move_toward(player.velocity.y, player.wall_slide_speed, (player.gravity * 0.8) * delta)
	player.move_and_slide()
