class_name ArcherDeathState
extends State

## Archer Death State:
## Manages death collapse, fade out, and optional respawn for test rooms.

var archer: Archer
var fade_timer: float = 0.5
var respawn_timer: float = 0.0
var is_waiting_respawn: bool = false

func enter() -> void:
	archer = character as Archer
	fade_timer = 0.5
	is_waiting_respawn = false
	archer.hide_telegraph()

	# Disable collision with player & attacks
	archer.set_collision_layer_value(3, false)
	archer.hurtbox.is_invulnerable = true
	if archer.hurtbox.has_node("CollisionShape2D"):
		archer.hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Death visual: flatten slightly & tint dark red
	archer.visual.scale.y = 0.4
	archer.visual.modulate = Color(0.6, 0.2, 0.2, 0.8)

	# Registra abate e almas colhidas no ProgressionManager
	ProgressionManager.record_kill(archer.enemy_category, archer.is_elite_active)
	ProgressionManager.add_souls(15 if archer.is_elite_active else 5)

func exit() -> void:
	if archer and archer.visual:
		archer.visual.visible = true
		archer.visual.scale.y = 1.0
		archer.visual.modulate = Color.WHITE

func physics_update(delta: float) -> void:
	# Fall to floor if in air
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
	archer.move_and_slide()

	if not is_waiting_respawn:
		fade_timer -= delta
		archer.visual.modulate.a = max(0.0, fade_timer / 0.5)

		if fade_timer <= 0.0:
			if archer.respawn_enabled:
				is_waiting_respawn = true
				respawn_timer = archer.respawn_delay
				archer.visual.visible = false
				archer.velocity = Vector2.ZERO
			else:
				archer.queue_free()
	else:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			archer.respawn()
