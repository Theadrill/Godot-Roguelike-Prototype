class_name LedgeClimbState
extends State

## Ledge Climb / Vault State (Dead Cells style).
## Snappy mantling onto the top surface of a platform when grabbing a ledge.

var player: Player
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var climb_timer: float = 0.0
const CLIMB_DURATION: float = 0.18

func enter() -> void:
	player = character as Player
	start_pos = player.global_position
	target_pos = player.ledge_target_position
	climb_timer = 0.0
	
	player.velocity = Vector2.ZERO
	player.set_ledge_climb_visual(true)
	
	# Reset jump allowances
	player.can_double_jump = true
	player.coyote_timer = player.coyote_duration

func exit() -> void:
	player.set_ledge_climb_visual(false)

func physics_update(delta: float) -> void:
	# Vault jump-cancel: pressing jump during climb vaults up and over
	if Input.is_action_just_pressed("jump"):
		player.global_position = target_pos
		player.velocity = Vector2(float(player.facing_direction) * player.run_speed * 0.8, player.jump_velocity * 0.95)
		state_machine.transition_to("jump")
		return

	# Roll-cancel: can roll directly onto the platform
	if Input.is_action_just_pressed("roll"):
		player.global_position = target_pos
		state_machine.transition_to("roll")
		return

	climb_timer += delta

	# Two-phase mantle: lift vertically first (0% - 60%), then step forward onto ledge (25% - 100%)
	var y_t := clampf(climb_timer / (CLIMB_DURATION * 0.6), 0.0, 1.0)
	var ease_y := y_t * y_t * (3.0 - 2.0 * y_t)

	var x_t := clampf((climb_timer - CLIMB_DURATION * 0.25) / (CLIMB_DURATION * 0.75), 0.0, 1.0)
	var ease_x := x_t * x_t * (3.0 - 2.0 * x_t)

	player.global_position.x = lerpf(start_pos.x, target_pos.x, ease_x)
	player.global_position.y = lerpf(start_pos.y, target_pos.y, ease_y)

	if climb_timer >= CLIMB_DURATION:
		player.global_position = target_pos
		player.velocity = Vector2.ZERO
		
		var move_dir := Input.get_axis("move_left", "move_right")
		if abs(move_dir) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
