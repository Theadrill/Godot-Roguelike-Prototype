class_name SoldierAttackState
extends State

enum AttackType {
	NORMAL,
	YELLOW,
	RED
}

var soldier: Soldier
var attack_type: AttackType = AttackType.NORMAL
var attack_phase: int = 0 # 0: Windup/Telegraph, 1: Active, 2: Recovery
var phase_timer: float = 0.0

# Predictable cycle to allow the player to test and learn all 3 signals:
# Normal -> Normal -> Yellow -> Red -> Repeat
static var cycle_index: int = 0

func enter() -> void:
	soldier = character as Soldier
	soldier.velocity.x = 0.0

	# Pick attack type from cycle
	match cycle_index % 4:
		0, 1:
			attack_type = AttackType.NORMAL
		2:
			attack_type = AttackType.YELLOW
		3:
			attack_type = AttackType.RED
	cycle_index += 1

	# Turn to face player at start of attack
	if soldier.target_player and is_instance_valid(soldier.target_player):
		var dir := signf(soldier.target_player.global_position.x - soldier.global_position.x)
		if dir != 0.0:
			soldier.update_facing(dir)

	# Configure Hyper-Armor and Visual Telegraph
	match attack_type:
		AttackType.NORMAL:
			soldier.is_hyper_armored = false
			soldier.hide_telegraph()
			phase_timer = soldier.telegraph_duration * 0.9 # ~0.4s
		AttackType.YELLOW:
			soldier.is_hyper_armored = true
			soldier.show_yellow_telegraph()
			phase_timer = soldier.telegraph_duration * 1.1 # ~0.5s
		AttackType.RED:
			soldier.is_hyper_armored = true
			soldier.show_red_telegraph()
			phase_timer = soldier.telegraph_duration * 1.25 # ~0.56s

	attack_phase = 0 # Windup
	soldier.set_slash_active(false)
	soldier.hitbox.set_active(false)

func exit() -> void:
	soldier.is_hyper_armored = false
	soldier.hide_telegraph()
	soldier.set_slash_active(false)
	soldier.hitbox.set_active(false)

func physics_update(delta: float) -> void:
	# Gravity
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	# Friction for any residual knockback/movement
	soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
	soldier.move_and_slide()

	phase_timer -= delta
	if phase_timer <= 0.0:
		_advance_phase()

func _advance_phase() -> void:
	match attack_phase:
		0:
			# Advance from Windup -> Active Swing
			attack_phase = 1
			phase_timer = 0.14
			soldier.hide_telegraph()
			soldier.set_slash_active(true)

			# Configure Hitbox stats based on attack type
			var damage: float = soldier.normal_damage
			var knockback: float = 140.0
			var rumble_strong: float = 0.6

			match attack_type:
				AttackType.YELLOW:
					damage = soldier.heavy_damage
					knockback = 220.0
					rumble_strong = 0.8
				AttackType.RED:
					damage = soldier.perilous_damage
					knockback = 320.0
					rumble_strong = 1.0

			soldier.hitbox.damage = damage
			soldier.hitbox.knockback_force = knockback
			soldier.hitbox.rumble_strong = rumble_strong
			soldier.hitbox.knockback_direction = Vector2(float(soldier.facing_direction), -0.2).normalized()
			soldier.hitbox.set_active(true)

			# Slight forward step during attack
			soldier.velocity.x = float(soldier.facing_direction) * 40.0

		1:
			# Advance from Active -> Recovery
			attack_phase = 2
			phase_timer = 0.35
			soldier.set_slash_active(false)
			soldier.hitbox.set_active(false)
			# Hyper-armor expires on recovery
			soldier.is_hyper_armored = false

		2:
			# Recovery complete: transition back to Chase or Patrol
			if soldier.target_player and is_instance_valid(soldier.target_player):
				state_machine.transition_to("chase")
			else:
				state_machine.transition_to("patrol")
