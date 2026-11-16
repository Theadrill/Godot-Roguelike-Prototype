class_name PickupState
extends State

## Pickup State:
## Plays the 3-frame pickup animation (ready -> pick up -> show) with main-hand and secondary weapons stowed,
## then holds the last frame for 0.20s leaving the player stationary and vulnerable before returning to idle/fall.

var player: Player
var _hold_timer: float = 0.0
var _is_holding_last_frame: bool = false
@export_range(0.0, 3.0, 0.05, "suffix:s") var last_frame_hold_duration: float = 0.20

func enter() -> void:
	player = character as Player
	_hold_timer = 0.0
	_is_holding_last_frame = false
	if player:
		player.velocity.x = 0.0
	if player and player.player_sprite:
		player.play_animation(&"pickup")
		player.player_sprite.frame = 0
		player._update_weapon_socket_for_frame(&"pickup", 0)

func exit() -> void:
	_is_holding_last_frame = false
	if player:
		player.clear_pickup_item_visual()

func handle_incoming_hit(_damage: float, _knockback: Vector2, _hitstop: float, _incoming_hitbox: Hitbox) -> bool:
	if player:
		player.clear_pickup_item_visual()
	return false

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	player.velocity.x = 0.0
	player.move_and_slide()

	if not _is_holding_last_frame:
		if player.player_sprite and player.player_sprite.frame >= 2 and not player.player_sprite.is_playing():
			_is_holding_last_frame = true
			_hold_timer = last_frame_hold_duration
			player._update_weapon_socket_for_frame(&"pickup", 2)
		return

	_hold_timer -= delta
	if _hold_timer <= 0.0:
		if player.is_on_floor():
			state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
