class_name ArcherPatrolState
extends State

## Archer Patrol State:
## Walks on platforms, detects player, and transitions to Aim or Kite.

var archer: Archer
var wait_timer: float = 0.0
var is_waiting: bool = false

func enter() -> void:
	archer = character as Archer
	archer.hide_telegraph()
	is_waiting = false
	wait_timer = 0.0

func physics_update(delta: float) -> void:
	# Gravity
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	# Scan for Player
	var player := _find_player()
	if player:
		var to_player := player.global_position - archer.global_position
		var dist := to_player.length()
		var dir_to_player := signf(to_player.x)
		var is_in_front: bool = (dir_to_player == float(archer.facing_direction)) or (dir_to_player == 0.0)
		var max_dist: float = archer.spot_range if is_in_front else archer.back_awareness_range

		if dist <= max_dist and archer.has_line_of_sight_to(player):
			archer.target_player = player
			if not is_in_front and dir_to_player != 0.0:
				archer.update_facing(dir_to_player)

			if archer.can_move and dist < archer.min_kite_distance and archer.can_step_backward():
				state_machine.transition_to("kite")
			else:
				state_machine.transition_to("aim")
			return

	if not archer.can_move or archer.stationary:
		archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
		archer.move_and_slide()
		return

	if is_waiting:
		wait_timer -= delta
		archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
		archer.move_and_slide()
		if wait_timer <= 0.0:
			is_waiting = false
			archer.update_facing(-archer.facing_direction)
		return

	# Move forward along patrol ledge
	if not archer.can_step_forward():
		is_waiting = true
		wait_timer = 1.0
		archer.velocity.x = 0.0
		archer.move_and_slide()
		return

	archer.velocity.x = float(archer.facing_direction) * archer.patrol_speed
	archer.move_and_slide()

func _find_player() -> Player:
	if archer.target_player and is_instance_valid(archer.target_player):
		return archer.target_player
	var tree := archer.get_tree()
	if not tree:
		return null
	var nodes := tree.get_nodes_in_group("player")
	if nodes.size() > 0 and nodes[0] is Player:
		return nodes[0] as Player
	if tree.current_scene:
		var p := tree.current_scene.find_child("Player", true, false)
		if p is Player:
			return p as Player
	return null
