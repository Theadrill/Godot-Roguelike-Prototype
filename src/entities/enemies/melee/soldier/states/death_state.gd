class_name SoldierDeathState
extends State

var soldier: Soldier
var fade_timer: float = 0.5
var respawn_timer: float = 0.0
var is_waiting_respawn: bool = false

func enter() -> void:
	soldier = character as Soldier
	fade_timer = 0.5
	is_waiting_respawn = false
	soldier.is_hyper_armored = false
	soldier.hide_telegraph()
	soldier.set_slash_active(false)
	soldier.hitbox.set_active(false)

	# Disable collision with player & attacks
	soldier.set_collision_layer_value(3, false)
	soldier.hurtbox.is_invulnerable = true
	if soldier.hurtbox.has_node("CollisionShape2D"):
		soldier.hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Death visual: flatten slightly & tint dark red
	soldier.visual.scale.y = 0.4
	soldier.visual.modulate = Color(0.6, 0.2, 0.2, 0.8)

	# Registra abate e almas colhidas no ProgressionManager
	ProgressionManager.record_kill(soldier.enemy_category, soldier.is_elite_active)
	ProgressionManager.add_souls(15 if soldier.is_elite_active else 5)

func physics_update(delta: float) -> void:
	# Fall to floor if in air
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
	soldier.move_and_slide()

	if not is_waiting_respawn:
		fade_timer -= delta
		soldier.visual.modulate.a = max(0.0, fade_timer / 0.5)

		if fade_timer <= 0.0:
			if soldier.respawn_enabled:
				# Hide and start respawn timer
				is_waiting_respawn = true
				respawn_timer = soldier.respawn_delay
				soldier.visual.visible = false
				soldier.velocity = Vector2.ZERO
			else:
				# Permanent death in standard gameplay
				soldier.queue_free()
	else:
		# Waiting for respawn delay (e.g. 5 seconds)
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn_soldier()

func _respawn_soldier() -> void:
	soldier.global_position = soldier.spawn_position
	soldier.current_health = soldier.max_health
	soldier.target_player = null
	soldier.velocity = Vector2.ZERO

	# Reset visuals
	soldier.visual.visible = true
	soldier.visual.modulate = Color.WHITE
	soldier.visual.scale = Vector2.ONE
	soldier.update_facing(float(soldier.initial_facing))

	# Re-enable collision and hurtbox
	soldier.set_collision_layer_value(3, true)
	soldier.hurtbox.is_invulnerable = false
	if soldier.hurtbox.has_node("CollisionShape2D"):
		soldier.hurtbox.get_node("CollisionShape2D").set_deferred("disabled", false)

	state_machine.transition_to("patrol")
