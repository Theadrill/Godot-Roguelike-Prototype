class_name SoldierHurtState
extends State

var soldier: Soldier
var stun_timer: float = 0.0

func enter() -> void:
	soldier = character as Soldier
	stun_timer = 0.22
	soldier.is_hyper_armored = false
	soldier.hide_telegraph()
	soldier.set_slash_active(false)
	soldier.hitbox.set_active(false)

func physics_update(delta: float) -> void:
	# Gravity & friction
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
	soldier.move_and_slide()

	stun_timer -= delta
	if stun_timer <= 0.0:
		# Recover from stunlock: face towards player and resume chase
		if soldier.target_player and is_instance_valid(soldier.target_player):
			var dir := signf(soldier.target_player.global_position.x - soldier.global_position.x)
			if dir != 0.0:
				soldier.update_facing(dir)
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("patrol")
