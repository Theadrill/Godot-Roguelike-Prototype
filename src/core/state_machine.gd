class_name StateMachine
extends Node

## Manages child State nodes and state transitions for an entity.
@export var initial_state: State

var current_state: State
var previous_state: State = null
var states: Dictionary = {}

func _ready() -> void:
	# Map all child State nodes by their lowercase name
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self

	# Ensure owner character is fully ready before entering initial state
	if owner and not owner.is_node_ready():
		await owner.ready

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
	if owner and "is_input_locked" in owner and owner.is_input_locked:
		return
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	var key: String = target_state_name.to_lower()
	if not states.has(key):
		push_warning("StateMachine: state '%s' does not exist." % target_state_name)
		return

	var new_state: State = states[key]
	if current_state == new_state:
		return

	previous_state = current_state

	if current_state:
		current_state.exit()

	if owner and owner.is_in_group("player"):
		RuntimeDebugger.log_event("PLAYER_FSM", "%s -> %s" % [current_state.name if current_state else "None", new_state.name])

	current_state = new_state
	new_state.enter()
