class_name GroundSlamState
extends State

## Aerial Ground Slam (Down + Jump in mid-air):
## Freezes horizontal speed, drives vertically down at 950 px/s, and creates a radial impact shockwave on floor touch.

var player: Player
var has_impacted: bool = false
var impact_recovery_timer: float = 0.0
var _dive_loop_accum: float = 0.0
var _dive_frame: int = 1

@export_range(600.0, 1400.0, 50.0, "suffix:px/s") var slam_speed: float = 950.0
@export_range(10.0, 100.0, 5.0) var slam_damage: float = 40.0
@export_range(40.0, 200.0, 10.0, "suffix:px") var shockwave_radius: float = 85.0
@export_range(100.0, 800.0, 20.0, "suffix:px/s") var shockwave_force: float = 360.0
@export_range(0.05, 0.4, 0.01, "suffix:s") var impact_recovery: float = 0.14

func enter() -> void:
	player = character as Player
	player.can_double_jump = false
	has_impacted = false
	impact_recovery_timer = 0.0
	_dive_loop_accum = 0.0
	_dive_frame = 1
	player.velocity.x = 0.0
	player.velocity.y = slam_speed

	player.play_animation(&"air_attack3")
	if player.player_sprite:
		player.player_sprite.pause()
		player.player_sprite.frame = _dive_frame
		player._update_weapon_socket_for_frame(&"air_attack3", _dive_frame)

	if player.visual:
		player.visual.scale = Vector2(float(player.facing_direction), 1.0)
	if player.main_hand_socket:
		player.main_hand_socket.rotation_degrees = 90.0

func exit() -> void:
	has_impacted = false
	player.stop_animation()
	if player.visual:
		player.visual.scale = Vector2(float(player.facing_direction), 1.0)
	if player.main_hand_socket:
		player.main_hand_socket.rotation_degrees = -35.0

func physics_update(delta: float) -> void:
	if not has_impacted:
		# Cycle dive frames (1..3) of air_attack3 during descent
		_dive_loop_accum += delta * 12.0
		if _dive_loop_accum >= 1.0:
			_dive_loop_accum -= 1.0
			_dive_frame = 1 + ((_dive_frame - 1 + 1) % 3)
			if player.player_sprite:
				player.player_sprite.frame = _dive_frame
				player._update_weapon_socket_for_frame(&"air_attack3", _dive_frame)

		# Lock horizontal velocity, drive downwards at slam speed
		player.velocity.x = 0.0
		player.velocity.y = slam_speed
		player.move_and_slide()

		if player.is_on_floor():
			_on_slam_impact()
	else:
		# Impact recovery holding crouch pose
		impact_recovery_timer -= delta
		player.velocity = Vector2.ZERO
		player.move_and_slide()

		if impact_recovery_timer <= 0.0:
			if player.visual:
				player.visual.scale = Vector2(float(player.facing_direction), 1.0)
			if player.is_crouch_requested():
				state_machine.transition_to("crouch")
				return
			var dir := Input.get_axis("move_left", "move_right")
			if abs(dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")

func _on_slam_impact() -> void:
	has_impacted = true
	impact_recovery_timer = impact_recovery
	player.fall_peak_y = player.global_position.y

	player.play_animation(&"crouch")

	# Heavy tactile rumble & screen hitstop
	CombatFeedback.apply_hit_feedback(0.08, 0.7, 1.0, 0.18)

	# Ground impact particles sized to shockwave width (uses equipped EnergizeProfile if active, else earth dust/rocks)
	player.spawn_ground_impact_particles(
		player.global_position.x,
		player.global_position.y,
		shockwave_radius * 1.1,
		player.facing_direction,
		"res://src/combat/energize_particles/earth_ground.tscn"
	)

	# Spawn RadialShockwave with area damage
	var shockwave_scene := load("res://src/combat/radial_shockwave.tscn") as PackedScene
	if shockwave_scene:
		var sw := shockwave_scene.instantiate() as RadialShockwave
		sw.global_position = player.global_position + Vector2(0.0, -4.0)
		sw.setup(
			shockwave_radius,
			shockwave_force,
			slam_damage,
			null,
			player,
			Color(1.0, 0.85, 0.35, 0.95)
		)
		player.get_parent().add_child(sw)
