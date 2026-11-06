class_name PlayerHUD
extends CanvasLayer

## Diegetic / Combat HUD displaying player health, delayed damage chip feedback,
## and real-time shield status (Guard, Parry Cooldown, Brother's Repulsion Modifier).

@export var player: Player

@onready var health_bar_damage: ColorRect = $MarginContainer/VBoxContainer/HealthBarContainer/DamageBar
@onready var health_bar_fill: ColorRect = $MarginContainer/VBoxContainer/HealthBarContainer/FillBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HealthBarContainer/HPLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var tier_label: Label = $MarginContainer/VBoxContainer/TierLabel
@onready var flask_icon: ColorRect = $MarginContainer/VBoxContainer/FlaskContainer/FlaskIcon
@onready var flask_label: Label = $MarginContainer/VBoxContainer/FlaskContainer/FlaskLabel

var _bar_max_width: float = 180.0

func _ready() -> void:
	if not player:
		if get_parent() is Player:
			player = get_parent() as Player
		elif get_tree() and get_tree().current_scene:
			player = get_tree().current_scene.find_child("Player", true, false) as Player

func show_tier_toast(tier_num: int, tier_name: String, player_level: int) -> void:
	if tier_label:
		tier_label.text = "⚔️ INIMIGOS: TIER %d [%s] - LV %d (Tecla T)" % [tier_num, tier_name, player_level]
		match tier_num:
			1:
				tier_label.modulate = Color(0.8, 0.85, 0.95, 0.85)
			2:
				tier_label.modulate = Color(0.35, 0.85, 1.0, 1.0)
			3:
				tier_label.modulate = Color(1.0, 0.35, 0.35, 1.0)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	var max_hp: float = player.max_health if player.max_health > 0.0 else 1.0
	var cur_hp: float = clampf(player.current_health, 0.0, max_hp)
	var hp_ratio: float = cur_hp / max_hp

	var target_fill_width: float = _bar_max_width * hp_ratio
	health_bar_fill.size.x = target_fill_width

	# Smooth delayed damage chip bar
	if health_bar_damage.size.x > target_fill_width:
		health_bar_damage.size.x = move_toward(health_bar_damage.size.x, target_fill_width, 120.0 * delta)
	else:
		health_bar_damage.size.x = target_fill_width

	# Health text
	hp_label.text = "HP %d / %d" % [int(ceilf(cur_hp)), int(max_hp)]

	# Shield & Revive status indicator
	if player.current_health <= 0.0:
		status_label.text = "● REVIVENDO (DEBUG)..."
		status_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	elif player.parry_cooldown_timer > 0.0:
		status_label.text = "● ESCUDO BLOQUEADO: %.1fs" % player.parry_cooldown_timer
		status_label.modulate = Color(1.0, 0.45, 0.4, 0.95)
	elif player.is_shield_raised:
		status_label.text = "● ESCUDO EM GUARDA"
		status_label.modulate = Color(0.35, 0.8, 1.0, 0.95)
	else:
		var rep_text := " [REPULSÃO ATIVA]" if (player.shield and player.shield.has_repulsion_modifier) else ""
		status_label.text = "● ESCUDO PRONTO%s" % rep_text
		status_label.modulate = Color(0.7, 0.75, 0.85, 0.75)

	# Health Flask (Mother's Tea) indicator using i18n
	if flask_label:
		var flask_name: String = tr("UI_FLASK_CHARGES")
		if player.current_flask_charges > 0:
			flask_label.text = "● %s: %d/%d [Q]" % [flask_name, player.current_flask_charges, player.max_flask_charges]
			flask_label.modulate = Color(0.25, 0.95, 0.5, 1.0)
			if flask_icon:
				flask_icon.color = Color(0.2, 0.9, 0.45, 1.0)
		else:
			flask_label.text = "○ %s: %d/%d [Q]" % [flask_name, player.current_flask_charges, player.max_flask_charges]
			flask_label.modulate = Color(0.7, 0.7, 0.7, 0.6)
			if flask_icon:
				flask_icon.color = Color(0.4, 0.4, 0.4, 0.5)
