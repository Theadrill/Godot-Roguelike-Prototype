class_name EnemyDeathState
extends State

## Shared Enemy Death State:
## Handles collapse visual, collision disable, ProgressionManager kill/soul rewards, fade-out, and respawn/free.

var enemy: BaseEnemy
var fade_timer: float = 0.5
var respawn_timer: float = 0.0
var is_waiting_respawn: bool = false


func enter() -> void:
	enemy = character as BaseEnemy
	is_waiting_respawn = false
	if not enemy:
		fade_timer = 0.5
		return

	fade_timer = enemy.death_dissolve_duration
	enemy.is_hyper_armored = false
	enemy.hide_telegraph()
	enemy._on_death_enter()

	# Disable collision with player & attacks
	enemy.set_collision_layer_value(3, false)
	if enemy.hurtbox:
		enemy.hurtbox.is_invulnerable = true
		if enemy.hurtbox.has_node("CollisionShape2D"):
			enemy.hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Death visual: final impact hit flash + pixel dissolve (keeps scale & white modulate crisp for shader)
	if enemy.visual:
		enemy.visual.scale.y = enemy.get_visual_scale_magnitude()
		enemy.visual.modulate = Color.WHITE
	enemy.trigger_hit_flash(0.09)
	enemy.set_dissolve_amount(0.0)

	ProgressionManager.record_kill(enemy.enemy_category, enemy.is_elite_active)
	ProgressionManager.add_souls(15 if enemy.is_elite_active else 5)


func exit() -> void:
	if enemy:
		enemy.set_dissolve_amount(0.0)
	if enemy and enemy.visual:
		enemy.visual.visible = true
		enemy.visual.scale.y = enemy.get_visual_scale_magnitude()
		enemy.visual.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	if not enemy:
		return

	if not enemy.is_on_floor():
		enemy.velocity.y += enemy.gravity * delta
	else:
		enemy.velocity.y = 0.0

	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.friction * delta)
	enemy.move_and_slide()

	if not is_waiting_respawn:
		fade_timer -= delta
		var duration: float = maxf(0.01, enemy.death_dissolve_duration)
		var progress: float = clampf(1.0 - (fade_timer / duration), 0.0, 1.0)
		enemy.set_dissolve_amount(progress)

		if fade_timer <= 0.0:
			if enemy.respawn_enabled:
				is_waiting_respawn = true
				respawn_timer = enemy.respawn_delay
				if enemy.visual:
					enemy.visual.visible = false
				enemy.velocity = Vector2.ZERO
			else:
				enemy.queue_free()
	else:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			enemy.respawn()
