class_name Soldier
extends BaseEnemy

## Basic melee soldier enemy extending BaseEnemy with 3-direction hitboxes and combo interruption rules.

@export_group("Soldier Specific")
@export_range(30.0, 400.0, 5.0, "suffix:px/s") var chase_speed: float = 85.0
@export_range(0.05, 0.5, 0.01, "suffix:s") var attack_active_duration: float = 0.14
@export_range(0.05, 0.5, 0.01, "suffix:s") var vertical_attack_active_duration: float = 0.16
@export_range(20.0, 500.0, 10.0, "suffix:px/s") var normal_knockback: float = 140.0
@export_range(20.0, 500.0, 10.0, "suffix:px/s") var heavy_knockback: float = 220.0
@export_range(20.0, 600.0, 10.0, "suffix:px/s") var perilous_knockback: float = 320.0
@export_range(0.05, 1.0, 0.05, "suffix:s") var chase_turn_cooldown: float = 0.25
@export_range(0.2, 5.0, 0.1, "suffix:s") var chase_los_grace_time: float = 1.2
@export_range(0.2, 3.0, 0.1, "suffix:s") var anti_air_cooldown: float = 0.9

@onready var slash_arc: Polygon2D = get_node_or_null("Visual/SlashArc") as Polygon2D
@onready var slash_arc_up: Polygon2D = get_node_or_null("Visual/SlashArcUp") as Polygon2D
@onready var slash_arc_down: Polygon2D = get_node_or_null("Visual/SlashArcDown") as Polygon2D
@onready var hitbox: Hitbox = get_node_or_null("Visual/Hitbox") as Hitbox
@onready var hitbox_up: Hitbox = get_node_or_null("Visual/HitboxUp") as Hitbox
@onready var hitbox_down: Hitbox = get_node_or_null("Visual/HitboxDown") as Hitbox


func _init() -> void:
	initial_facing = 1
	max_health = 60.0
	patrol_speed = 40.0
	spot_range = 160.0
	back_awareness_range = 64.0
	attack_range = 26.0
	lose_target_range = 240.0
	normal_damage = 12.0
	heavy_damage = 20.0
	perilous_damage = 32.0
	telegraph_duration = 0.45
	hurt_stun_duration = 0.22
	patrol_wait_duration = 0.4
	attack_cooldown = 2.0
	cooldown_speed_mult = 0.45
	tier_1_behavior = CooldownBehavior.AGGRESSIVE_STALK
	tier_2_behavior = CooldownBehavior.AGGRESSIVE_STALK
	tier_3_has_hyper_armor = true
	respawn_enabled = false
	respawn_delay = 5.0


func _on_enemy_ready() -> void:
	deactivate_all_attacks()
	if hitbox:
		hitbox.attacker = self
	if hitbox_up:
		hitbox_up.attacker = self
	if hitbox_down:
		hitbox_down.attacker = self


func _on_parry_stun_applied(_duration: float) -> void:
	deactivate_all_attacks()


func _on_death_enter() -> void:
	deactivate_all_attacks()


func _on_enemy_respawn() -> void:
	deactivate_all_attacks()


func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	if state_machine and state_machine.current_state is EnemyDeathState:
		return

	current_health -= damage
	trigger_hit_flash(hitstop + 0.06)

	if visual:
		visual.scale = Vector2(visual.scale.x, 0.75 * get_visual_scale_magnitude())

	if current_health <= 0.0:
		state_machine.transition_to("death")
		return

	if not target_player or not is_instance_valid(target_player):
		target_player = find_player()

	# Interruption rules:
	# - Normal: interrupted by any hit.
	# - Yellow / Upward / Downward: only interrupted by finisher (combo_step >= 3).
	# - Red: cannot be interrupted.
	var incoming_hitbox: Hitbox = hurtbox.last_hitbox if hurtbox else null
	var combo_step: int = incoming_hitbox.combo_step if incoming_hitbox else 1
	var is_finisher: bool = (combo_step >= 3)

	if not takes_knockback or not can_move:
		knockback = Vector2.ZERO

	var can_interrupt: bool = false
	if state_machine and state_machine.current_state is SoldierAttackState:
		var attack_state := state_machine.current_state as SoldierAttackState
		match attack_state.attack_type:
			SoldierAttackState.AttackType.NORMAL:
				can_interrupt = true
			SoldierAttackState.AttackType.YELLOW, SoldierAttackState.AttackType.UPWARD, SoldierAttackState.AttackType.DOWNWARD:
				can_interrupt = is_finisher
			SoldierAttackState.AttackType.RED:
				can_interrupt = false
	else:
		can_interrupt = true

	if can_interrupt:
		velocity = knockback
		if absf(knockback.x) > 1.0:
			update_facing(-signf(knockback.x))
		state_machine.transition_to("hurt")
	else:
		velocity = Vector2.ZERO


func deactivate_all_attacks() -> void:
	set_slash_active(false)
	set_slash_up_active(false)
	set_slash_down_active(false)
	if hitbox:
		hitbox.set_active(false)
	if hitbox_up:
		hitbox_up.set_active(false)
	if hitbox_down:
		hitbox_down.set_active(false)


func set_slash_color(col: Color) -> void:
	if slash_arc:
		slash_arc.color = col
	if slash_arc_up:
		slash_arc_up.color = col
	if slash_arc_down:
		slash_arc_down.color = col


func set_slash_active(active: bool) -> void:
	if slash_arc:
		slash_arc.visible = active


func set_slash_up_active(active: bool) -> void:
	if slash_arc_up:
		slash_arc_up.visible = active


func set_slash_down_active(active: bool) -> void:
	if slash_arc_down:
		slash_arc_down.visible = active
