class_name LedgeClimbState
extends State

## Ledge Climb / Vault State (Dead Cells style).
## Snappy mantling onto the top surface of a platform when grabbing a ledge.

var player: Player
var corner_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var climb_timer: float = 0.0
const CLIMB_DURATION: float = 0.24

func enter() -> void:
	player = character as Player
	target_pos = player.ledge_target_position
	var face: float = float(player.facing_direction)
	# Corner contact point is (wall_x, floor_y)
	corner_pos = Vector2(target_pos.x - (face * 10.0), target_pos.y)
	
	climb_timer = 0.0
	player.velocity = Vector2.ZERO
	# Pinned to the corner during mantle animation
	player.global_position = corner_pos
	
	player.set_ledge_climb_visual(true)
	if player.player_sprite:
		player.player_sprite.play(&"corner_climb")
		player.player_sprite.frame = 0
	
	# Reset jump allowances
	player.can_double_jump = true
	player.coyote_timer = player.coyote_duration
	player.is_wall_recovery_active = false

func exit() -> void:
	player.set_ledge_climb_visual(false)
	if player.player_sprite:
		player.player_sprite.position = Vector2(-2, -29)

func physics_update(delta: float) -> void:
	# Vault jump-cancel: pressing jump during climb vaults up and over
	if Input.is_action_just_pressed("jump"):
		player.global_position = target_pos
		player.velocity = Vector2(float(player.facing_direction) * player.run_speed * 0.8, player.jump_velocity * 0.95)
		state_machine.transition_to("jump")
		return

	# Roll-cancel: can roll directly onto the platform
	if player.is_roll_requested():
		player.global_position = target_pos
		state_machine.transition_to("roll")
		return

	climb_timer += delta

	# Pinned to the corner with frame synchronized to mantle duration
	player.global_position = corner_pos
	var progress := clampf(climb_timer / CLIMB_DURATION, 0.0, 1.0)
	var frame_idx := mini(int(progress * 5.0), 4)
	if player.player_sprite and player.player_sprite.animation == &"corner_climb":
		player.player_sprite.frame = frame_idx

	if climb_timer >= CLIMB_DURATION:
		player.global_position = target_pos
		player.velocity = Vector2.ZERO
		
		var move_dir := Input.get_axis("move_left", "move_right")
		if abs(move_dir) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
