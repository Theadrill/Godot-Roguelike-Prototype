class_name DeathState
extends State

## Death State:
## Trava controles, toca a animacao `death`, solta os equipamentos com fisica no chao
## (sem clipar em paredes) e conduz o takeover vermelho da tela antes da espiral de morte.

@export_range(0.4, 4.0, 0.05, "suffix:s") var takeover_duration: float = 1.40
## Tempo que o personagem permanece ajoelhado (frame 0) antes de tombar no chao (frame 1).
@export_range(0.1, 2.5, 0.05, "suffix:s") var kneel_hold_duration: float = 0.65

var player: Player
var _death_timer: float = 0.0
var _has_collapsed: bool = false
var _spiral_started: bool = false

func enter() -> void:
	player = character as Player
	_death_timer = 0.0
	_has_collapsed = false
	_spiral_started = false
	if not player:
		return

	player.velocity.x = 0.0
	player.play_animation(&"death")
	if player.player_sprite:
		player.player_sprite.pause()
		player.player_sprite.frame = 0
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
	if not _has_collapsed and _death_timer >= kneel_hold_duration:
		_has_collapsed = true
		if player.player_sprite and player.player_sprite.animation == &"death":
			player.player_sprite.frame = 1

	if _death_timer >= takeover_duration:
		_spiral_started = true
		player.trigger_death_screen()
