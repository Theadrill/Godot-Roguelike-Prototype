class_name ArcherKiteState
extends State

## Archer Kite State:
## Tactically walks backwards away from player to maintain safe shooting distance.

var archer: Archer
var max_kite_duration: float = 1.2
var kite_timer: float = 0.0

func enter() -> void:
	archer = character as Archer
	archer.hide_telegraph()
	kite_timer = 0.0

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
	kite_timer += delta

	# If reached comfortable distance or cornered or kited for long enough -> AIM and SHOOT!
	if dist >= archer.min_kite_distance * 1.3 or not archer.can_step_backward() or kite_timer >= max_kite_duration:
		state_machine.transition_to("aim")
		return

	# Walk backwards away from player
	archer.velocity.x = -float(archer.facing_direction) * archer.kite_speed
	archer.move_and_slide()
