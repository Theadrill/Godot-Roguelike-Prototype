class_name ArcherKiteState
extends State

## Archer Kite State:
## Tactically walks backwards away from player to maintain safe shooting distance.

var archer: Archer
var max_kite_duration: float = 1.2
var kite_timer: float = 0.0
var _no_angle_timer: float = 0.0
var _move_sign: int = -1 # -1: step backward away from player, +1: step forward to seek angle

func enter() -> void:
	archer = character as Archer
	archer.hide_telegraph()
	kite_timer = 0.0
	_no_angle_timer = 0.0
	_move_sign = -1 if archer.can_step_backward() else 1

func physics_update(delta: float) -> void:
	# Gravity
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	var player := archer.target_player
	if not is_instance_valid(player):
		state_machine.transition_to("patrol")
		return

	if not archer.can_move:
		state_machine.transition_to("aim")
		return

	# Face the player at all times while kiting
	var diff: Vector2 = player.global_position - archer.global_position
	var face_dir: float = signf(diff.x)
	if face_dir != 0.0:
		archer.update_facing(face_dir)

	var dist: float = diff.length()
	var has_angle: bool = archer.has_valid_shot_angle(player)
	kite_timer += delta

	if has_angle:
		_no_angle_timer = 0.0
		if dist >= archer.min_kite_distance * 1.3 or not archer.can_step_backward() or kite_timer >= archer.kite_max_duration:
			state_machine.transition_to("aim")
			return
	else:
		_no_angle_timer += delta
		if _no_angle_timer >= archer.lose_aggro_time or dist > archer.lose_target_range:
			archer.drop_aggro()
			state_machine.transition_to("patrol")
			return

	# Walk along platform trying to find a valid angle (retreat first, or advance if cornered)
	if _move_sign == -1 and not archer.can_step_backward():
		_move_sign = 1
	elif _move_sign == 1 and not archer.can_step_forward():
		if archer.can_step_backward():
			_move_sign = -1
		else:
			archer.velocity.x = 0.0
			archer.move_and_slide()
			return

	archer.velocity.x = float(archer.facing_direction * _move_sign) * archer.kite_speed
	archer.move_and_slide()
