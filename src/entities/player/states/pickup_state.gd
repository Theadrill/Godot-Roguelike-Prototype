class_name PickupState
extends State

## Pickup State:
## Plays the 2-frame pickup animation with main-hand and secondary weapons stowed on the back/waist.

var player: Player
var _timer: float = 0.0
@export_range(0.15, 0.8, 0.02, "suffix:s") var pickup_duration: float = 0.34

func enter() -> void:
	player = character as Player
	_timer = pickup_duration
	if player and player.player_sprite:
		player.play_animation(&"pickup")
		player.player_sprite.frame = 0
		player._update_weapon_socket_for_frame(&"pickup", 0)

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	player.velocity.x = move_toward(player.velocity.x, 0.0, 900.0 * delta)
	player.move_and_slide()

	_timer -= delta
	if _timer <= 0.0:
		if player.is_on_floor():
			state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
