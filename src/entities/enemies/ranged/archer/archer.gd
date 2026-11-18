class_name Archer
extends BaseEnemy

## Ranged Archer Enemy:
## Extends BaseEnemy with tactical kiting, bow aiming angle clamps, and arrow spawn helpers.

@export_group("Archer Specific")
@export_range(30.0, 300.0, 5.0, "suffix:px/s") var kite_speed: float = 75.0
@export_range(200.0, 1200.0, 50.0, "suffix:px/s") var arrow_speed: float = 520.0
@export_range(5.0, 45.0, 1.0, "suffix:deg") var max_aim_angle_deg: float = 25.0
@export_range(0.2, 4.0, 0.1, "suffix:s") var kite_max_duration: float = 1.2
@export_range(1.0, 2.5, 0.05) var heavy_arrow_speed_mult: float = 1.2
@export_range(1.0, 2.5, 0.05) var perilous_arrow_speed_mult: float = 1.35
@export_range(0.0, 200.0, 5.0, "suffix:px/s") var bow_recoil_speed: float = 40.0

var min_kite_distance: float:
	get: return attack_range
	set(val): attack_range = val

var shoot_cooldown: float:
	get: return attack_cooldown
	set(val): attack_cooldown = val

@onready var bow_node: Node2D = get_node_or_null("Visual/Bow") as Node2D
@onready var arrow_spawn_marker: Marker2D = get_node_or_null("Visual/Bow/ArrowSpawn") as Marker2D


func _init() -> void:
	max_health = 45.0
	patrol_speed = 35.0
	spot_range = 340.0
	back_awareness_range = 140.0
	attack_range = 95.0
	lose_target_range = 420.0
	normal_damage = 16.0
	heavy_damage = 24.0
	perilous_damage = 35.0
	telegraph_duration = 0.50
	hurt_stun_duration = 0.25
	patrol_wait_duration = 1.0
	cooldown_speed_mult = 0.50
	tier_1_behavior = CooldownBehavior.DEFENSIVE_RETREAT
	tier_2_behavior = CooldownBehavior.DEFENSIVE_RETREAT
	respawn_enabled = true
	respawn_delay = 4.0


func _get_tier_body_color() -> Color:
	if is_elite_active:
		return Color(0.85, 0.22, 0.25, 1.0)
	if active_tier == 3:
		return Color(0.55, 0.25, 0.45, 1.0)
	if active_tier == 2:
		return Color(0.2, 0.4, 0.55, 1.0)
	return Color(0.25, 0.45, 0.35, 1.0)


func _on_hit_received(amount: float, knockback: Vector2, hitstop: float) -> void:
	if state_machine and state_machine.current_state is EnemyDeathState:
		return

	current_health -= amount
	trigger_hit_flash()

	if not takes_knockback or not can_move:
		knockback = Vector2.ZERO

	if current_health <= 0.0:
		state_machine.transition_to("death")
	else:
		var hurt_state := state_machine.get_node_or_null("Hurt") as ArcherHurtState
		if hurt_state:
			hurt_state.incoming_knockback = knockback
			hurt_state.hitstop_time = hitstop
			state_machine.transition_to("hurt")


func _on_parry_stun_applied(_duration: float) -> void:
	if bow_node:
		bow_node.rotation = 0.0


func _on_death_enter() -> void:
	if bow_node:
		bow_node.rotation = 0.0


func _on_enemy_respawn() -> void:
	if bow_node:
		bow_node.rotation = 0.0


func get_arrow_spawn_pos() -> Vector2:
	if arrow_spawn_marker:
		return arrow_spawn_marker.global_position
	return global_position + Vector2(float(facing_direction) * 16.0, -20.0)


func is_target_within_aim_angle(target_pos: Vector2) -> bool:
	var diff: Vector2 = target_pos - get_arrow_spawn_pos()
	var abs_x: float = absf(diff.x)
	if abs_x < 8.0:
		return absf(diff.y) < 12.0
	var max_tan: float = tan(deg_to_rad(max_aim_angle_deg))
	return absf(diff.y) <= abs_x * max_tan


func get_clamped_aim_direction(target_pos: Vector2) -> Vector2:
	var diff: Vector2 = target_pos - get_arrow_spawn_pos()
	var dir_x: float = float(facing_direction)
	var abs_x: float = maxf(16.0, absf(diff.x))
	var max_dy: float = abs_x * tan(deg_to_rad(max_aim_angle_deg))
	var clamped_dy: float = clampf(diff.y, -max_dy, max_dy)
	return Vector2(dir_x * abs_x, clamped_dy).normalized()


func has_valid_shot_angle(player: Player) -> bool:
	if not is_instance_valid(player):
		return false
	return has_line_of_sight_to(player) and is_target_within_aim_angle(player.global_position + Vector2(0.0, -20.0))
