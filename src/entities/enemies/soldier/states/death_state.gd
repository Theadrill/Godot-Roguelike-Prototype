class_name SoldierDeathState
extends State

var soldier: Soldier
var death_timer: float = 0.5

func enter() -> void:
	soldier = character as Soldier
	soldier.is_hyper_armored = false
	soldier.hide_telegraph()
	soldier.set_slash_active(false)
	soldier.hitbox.set_active(false)

	# Disable collision with player & attacks
	soldier.set_collision_layer_value(3, false)
	soldier.hurtbox.is_invulnerable = true
	if soldier.hurtbox.has_node("CollisionShape2D"):
		soldier.hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Death visual: flatten slightly
	soldier.visual.scale.y = 0.4
	soldier.visual.modulate = Color(0.6, 0.2, 0.2, 0.8)

func physics_update(delta: float) -> void:
	# Fall to floor if in air
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
	soldier.move_and_slide()

	death_timer -= delta
	soldier.visual.modulate.a = max(0.0, death_timer / 0.5)

	if death_timer <= 0.0:
		soldier.queue_free()
