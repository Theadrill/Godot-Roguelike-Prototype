class_name ArcherAimState
extends State

## Archer Aim State:
## Faces player, chooses 3-signal telegraph (White / Yellow / Red), draws bow string, and readies arrow.

var archer: Archer
var aim_timer: float = 0.0
var _no_angle_timer: float = 0.0

func enter() -> void:
	archer = character as Archer
	aim_timer = archer.telegraph_duration
	_no_angle_timer = 0.0
	archer.velocity.x = 0.0

	var player := archer.target_player
	if is_instance_valid(player):
		var diff := player.global_position - archer.global_position
		if diff.x != 0.0:
			archer.update_facing(signf(diff.x))
		if not archer.has_valid_shot_angle(player):
			if archer.can_move:
				state_machine.transition_to("kite")
				return
			archer.hide_telegraph()
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

	# Keep enemy bow pose horizontal; if LoS or vertical angle is lost, reposition or drop aggro
	if archer.bow_node:
		archer.bow_node.rotation = 0.0
	if not archer.has_valid_shot_angle(player):
		if archer.can_move:
			state_machine.transition_to("kite")
			return
		archer.hide_telegraph()
		_no_angle_timer += delta
		if _no_angle_timer >= archer.lose_aggro_time:
			archer.drop_aggro()
			state_machine.transition_to("patrol")
		return

	_no_angle_timer = 0.0
	aim_timer -= delta
	if aim_timer <= 0.0:
		state_machine.transition_to("shoot")
