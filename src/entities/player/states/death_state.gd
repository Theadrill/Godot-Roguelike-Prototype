class_name DeathState
extends State

## Death State:
## Trava controles, toca a animacao `death`, solta os equipamentos com fisica no chao
## (sem clipar em paredes) e conduz o takeover vermelho da tela antes da espiral de morte.

@export_range(0.4, 4.0, 0.05, "suffix:s") var takeover_duration: float = 1.40

var player: Player
var _death_timer: float = 0.0
var _spiral_started: bool = false

func enter() -> void:
	player = character as Player
	_death_timer = 0.0
	_spiral_started = false
	if not player:
		return

	player.velocity.x = 0.0
	player.play_animation(&"death")
	player.spawn_death_dropped_equipment()
	player.are_weapons_hidden = true
	player._update_weapon_socket_for_frame(&"death", 0)

	if player.low_health_vignette:
		player.low_health_vignette.play_death_takeover(takeover_duration)

func exit() -> void:
	if player:
		player.are_weapons_hidden = false

func handle_incoming_hit(_damage: float, _knockback: Vector2, _hitstop: float, _incoming_hitbox: Hitbox) -> bool:
	return true

func physics_update(delta: float) -> void:
	if not player:
		return

	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	if player.is_on_wall():
		player.velocity.x = 0.0
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 900.0 * delta)

	player.move_and_slide()

	if _spiral_started:
		return

	_death_timer += delta
	if _death_timer >= takeover_duration:
		_spiral_started = true
		player.trigger_death_screen()
