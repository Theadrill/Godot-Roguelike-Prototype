class_name ArcherAimState
extends State

## Archer Aim State:
## Faces player, chooses 3-signal telegraph (White / Yellow / Red), draws bow string, and readies arrow.

var archer: Archer
var aim_timer: float = 0.0

func enter() -> void:
	archer = character as Archer
	aim_timer = archer.telegraph_duration
	archer.velocity.x = 0.0

	var player := archer.target_player
	if is_instance_valid(player):
		var diff := player.global_position - archer.global_position
		if diff.x != 0.0:
			archer.update_facing(signf(diff.x))
		var target_pos := player.global_position + Vector2(0.0, -20.0)
		if archer.can_move and archer.can_step_backward() and not archer.is_target_within_aim_angle(target_pos):
			state_machine.transition_to("kite")
			return

	# Choose next 3-signal telegraph (White / Yellow / Red)
	var attack_type := archer.advance_attack_cycle()
	archer.show_telegraph(attack_type)

	# Keep enemy bow pose horizontal (only projectile tilts slightly on Y)
	if archer.bow_node:
		archer.bow_node.rotation = 0.0

func exit() -> void:
	if archer.bow_node:
		archer.bow_node.rotation = 0.0

func physics_update(delta: float) -> void:
	# Gravity
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
	archer.move_and_slide()

	var player := archer.target_player
	if not is_instance_valid(player):
		state_machine.transition_to("patrol")
		return

	# Keep enemy bow pose horizontal; if target moves into a steep vertical angle, reposition
	if archer.bow_node:
		archer.bow_node.rotation = 0.0
	var target_pos := player.global_position + Vector2(0.0, -20.0)
	if not archer.is_target_within_aim_angle(target_pos):
		if archer.can_move and archer.can_step_backward():
			state_machine.transition_to("kite")
		return

	aim_timer -= delta
	if aim_timer <= 0.0:
		state_machine.transition_to("shoot")
