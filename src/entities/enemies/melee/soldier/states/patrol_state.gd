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
		if not soldier.can_move:
			# Immovable: only attack if in attack range; otherwise stay rooted and face player
			var dist := soldier.global_position.distance_to(soldier.target_player.global_position)
			if dist <= soldier.attack_range:
				state_machine.transition_to("attack")
				return
		else:
			state_machine.transition_to("chase")
			return

	# If immovable or stationary, stay in place watching for player
	if not soldier.can_move or soldier.stationary:
		soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
		soldier.move_and_slide()
		return

	# Handle brief pause at turnarounds
	if wait_timer > 0.0:
		wait_timer -= delta
		soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
		soldier.move_and_slide()
		return

	# Check ledge and wall ahead
	if soldier.is_on_wall() or not soldier.can_step_forward(12.0):
		soldier.update_facing(-soldier.facing_direction)
		wait_timer = soldier.patrol_wait_duration
		soldier.velocity.x = 0.0
		return

	# Move forward
	soldier.velocity.x = float(soldier.facing_direction) * soldier.patrol_speed
	soldier.move_and_slide()

## Raycast check: Line of Sight to Player
func _can_see_player() -> bool:
	var player: Player = soldier.find_player()
	if not player:
		return false

	var to_player: Vector2 = player.global_position - soldier.global_position
	var dist: float = to_player.length()

	var dir_to_player: float = signf(to_player.x)
	var is_in_front: bool = (dir_to_player == float(soldier.facing_direction))

	# Range check: spot_range if in front, back_awareness_range if behind
	var max_allowed_dist: float = soldier.spot_range if is_in_front else soldier.back_awareness_range
	if dist > max_allowed_dist:
		return false

	# Check direct line of sight (no walls blocking)
	if soldier.has_line_of_sight_to(player):
		soldier.target_player = player
		# If sensed from behind, turn to face player immediately
		if not is_in_front and dir_to_player != 0.0:
			soldier.update_facing(dir_to_player)
		return true

	return false
