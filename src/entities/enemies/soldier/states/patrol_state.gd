class_name SoldierPatrolState
extends State

var soldier: Soldier
var wait_timer: float = 0.0

func enter() -> void:
	soldier = character as Soldier
	wait_timer = 0.0
	soldier.hide_telegraph()
	soldier.is_hyper_armored = false

func physics_update(delta: float) -> void:
	# Gravity
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	# Check for Player in Line of Sight
	if _can_see_player():
		state_machine.transition_to("chase")
		return

	# Handle brief pause at turnarounds
	if wait_timer > 0.0:
		wait_timer -= delta
		soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
		soldier.move_and_slide()
		return

	# Check ledge and wall ahead
	if _is_at_ledge() or _is_hitting_wall():
		soldier.update_facing(-soldier.facing_direction)
		wait_timer = 0.4
		soldier.velocity.x = 0.0
		return

	# Move forward
	soldier.velocity.x = float(soldier.facing_direction) * soldier.patrol_speed
	soldier.move_and_slide()

## Raycast check: Ledge detection ahead
func _is_at_ledge() -> bool:
	var space := soldier.get_world_2d().direct_space_state
	var check_x: float = soldier.global_position.x + (soldier.facing_direction * 12.0)
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(check_x, soldier.global_position.y - 2.0),
		Vector2(check_x, soldier.global_position.y + 16.0),
		1 # Layer 1: Environment
	)
	var hit := space.intersect_ray(query)
	# If no floor hit, a cliff/ledge is ahead!
	return hit.is_empty()

## Raycast check: Wall ahead
func _is_hitting_wall() -> bool:
	if soldier.is_on_wall():
		return true
	var space := soldier.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		soldier.global_position + Vector2(0.0, -10.0),
		soldier.global_position + Vector2(soldier.facing_direction * 14.0, -10.0),
		1 # Layer 1: Environment
	)
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

## Raycast check: Line of Sight to Player
func _can_see_player() -> bool:
	var player: Player = _get_player()
	if not player:
		return false

	var to_player: Vector2 = player.global_position - soldier.global_position
	var dist: float = to_player.length()

	if dist > soldier.spot_range:
		return false

	# Must be roughly in facing direction unless very close (within 32px)
	var dir_to_player: float = signf(to_player.x)
	if dist > 32.0 and dir_to_player != float(soldier.facing_direction):
		return false

	# Check direct line of sight (no walls blocking)
	var space := soldier.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		soldier.global_position + Vector2(0.0, -20.0),
		player.global_position + Vector2(0.0, -20.0),
		1 # Layer 1: Environment
	)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		soldier.target_player = player
		return true

	return false

func _get_player() -> Player:
	if soldier.target_player and is_instance_valid(soldier.target_player):
		return soldier.target_player
	var tree := soldier.get_tree()
	if not tree:
		return null
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		return players[0] as Player
	# Fallback: scan root scene
	var root := tree.current_scene
	if root:
		var p := root.find_child("Player", true, false)
		if p is Player:
			return p as Player
	return null
