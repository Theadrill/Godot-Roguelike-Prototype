class_name PickupItem
extends Node2D

## Base collectible world item used to trigger the player's pickup animation and collect rewards.

@export var respawn_for_test: bool = true
@export_range(0.3, 5.0, 0.1, "suffix:s") var respawn_delay: float = 1.5

@onready var visual: Node2D = $Visual
@onready var prompt_label: Label = $PromptLabel
@onready var interact_area: Area2D = $InteractArea

var _player_near: Player = null
var _is_collected: bool = false
var _base_visual_y: float = -10.0

func _ready() -> void:
	if visual:
		_base_visual_y = visual.position.y
	if prompt_label:
		prompt_label.text = tr("UI_PICKUP_PROMPT")
		prompt_label.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _is_collected:
		return
	if visual:
		visual.position.y = _base_visual_y + sin(Time.get_ticks_msec() * 0.005) * 2.5

func _unhandled_input(event: InputEvent) -> void:
	if _is_collected or not is_instance_valid(_player_near):
		return
	if event.is_action_pressed("interact"):
		_collect()
		get_viewport().set_input_as_handled()

func _collect() -> void:
	_is_collected = true
	if prompt_label:
		prompt_label.visible = false
	if visual:
		visual.visible = false

	var dx: float = global_position.x - _player_near.global_position.x
	if absf(dx) > 2.0:
		_player_near.update_facing(signf(dx))
	_player_near.trigger_pickup_animation()

	if respawn_for_test:
		await get_tree().create_timer(respawn_delay).timeout
		if is_instance_valid(self):
			_is_collected = false
			if visual:
				visual.visible = true
			if prompt_label and is_instance_valid(_player_near):
				prompt_label.visible = true
	else:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_near = body as Player
		if prompt_label and not _is_collected:
			prompt_label.text = tr("UI_PICKUP_PROMPT")
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == _player_near:
		_player_near = null
		if prompt_label:
			prompt_label.visible = false
