class_name ArcherHurtState
extends State

## Archer Hurt State:
## Manages hit feedback, stagger/stunlock, and knockback absorption.

var archer: Archer
var stun_timer: float = 0.0
var custom_stun_duration: float = 0.0
var incoming_knockback: Vector2 = Vector2.ZERO
var hitstop_time: float = 0.0

func enter() -> void:
	archer = character as Archer
	stun_timer = custom_stun_duration if custom_stun_duration > 0.0 else archer.hurt_stun_duration
	custom_stun_duration = 0.0
	archer.reaggro_cooldown = 0.0
	archer.hide_telegraph()
	if archer.bow_node:
		archer.bow_node.rotation = 0.0

	# Apply initial knockback impulse
	archer.velocity = incoming_knockback
	incoming_knockback = Vector2.ZERO

func physics_update(delta: float) -> void:
	# Gravity & friction
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
	archer.move_and_slide()

	stun_timer -= delta
	if stun_timer <= 0.0:
		var player := archer.find_player()
		if is_instance_valid(player):
			archer.target_player = player

		if is_instance_valid(player) and archer.has_line_of_sight_to(player):
			var dist := archer.global_position.distance_to(player.global_position)
			if archer.can_move and ((dist < archer.min_kite_distance and archer.can_step_backward()) or not archer.has_valid_shot_angle(player)):
				state_machine.transition_to("kite")
			elif archer.has_valid_shot_angle(player):
				state_machine.transition_to("aim")
			else:
				state_machine.transition_to("patrol")
		else:
			state_machine.transition_to("patrol")
