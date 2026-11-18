class_name InteractableArea
extends Area2D

## Componente reutilizável de área interativa no mundo (Regra 9 - DRY).
## Unifica detecção de proximidade do jogador, clique esquerdo de mouse e ação de interação.

signal interacted(actor: Node2D)
signal proximity_changed(is_near: bool, actor: Node2D)

@export var interact_action: StringName = &"interact"
@export var allow_mouse_click: bool = true
@export var handle_unhandled_interact: bool = true

var _nearby_actor: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if allow_mouse_click:
		input_event.connect(_on_area_input_event)


func _unhandled_input(event: InputEvent) -> void:
	if not handle_unhandled_interact or not is_instance_valid(_nearby_actor):
		return
	if _is_actor_input_locked(_nearby_actor):
		return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		interacted.emit(_nearby_actor)


func is_actor_near() -> bool:
	return is_instance_valid(_nearby_actor)


## Conecta uma Area2D existente ao padrão único de proximidade + clique esquerdo sem duplicar callbacks.
static func bind_area(
	area: Area2D,
	player_ref: Node2D,
	on_interact: Callable,
	on_proximity_changed: Callable = Callable(),
	allow_click: bool = true
) -> void:
	if not area:
		return

	if on_proximity_changed.is_valid():
		area.body_entered.connect(func(body: Node2D) -> void:
			if _matches_actor(body, player_ref):
				on_proximity_changed.call(true)
		)
		area.body_exited.connect(func(body: Node2D) -> void:
			if _matches_actor(body, player_ref):
				on_proximity_changed.call(false)
		)

	if allow_click and on_interact.is_valid():
		area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
			if _is_actor_input_locked(player_ref):
				return
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				on_interact.call()
		)


static func _matches_actor(body: Node2D, player_ref: Node2D) -> bool:
	if player_ref:
		return body == player_ref
	return body != null and body.is_in_group("player")


static func _is_actor_input_locked(actor: Node2D) -> bool:
	return actor != null and "is_input_locked" in actor and actor.is_input_locked


func _on_body_entered(body: Node2D) -> void:
	if _matches_actor(body, null):
		_nearby_actor = body
		proximity_changed.emit(true, body)


func _on_body_exited(body: Node2D) -> void:
	if body == _nearby_actor:
		_nearby_actor = null
		proximity_changed.emit(false, body)


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_actor_input_locked(_nearby_actor):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var actor: Node2D = _nearby_actor
		if not actor:
			var tree := get_tree()
			if tree:
				actor = tree.get_first_node_in_group("player") as Node2D
		if not _is_actor_input_locked(actor):
			interacted.emit(actor)
