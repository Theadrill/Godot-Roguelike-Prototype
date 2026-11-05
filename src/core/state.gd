class_name State
extends Node

## Base interface for all Finite State Machine (FSM) states.
@onready var character: CharacterBody2D = owner
var state_machine: StateMachine = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
