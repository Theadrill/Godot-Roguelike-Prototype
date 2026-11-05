---
name: godot-programming
description: >-
  Godot 4 and GDScript 2.0 programming best practices, node-based Finite State Machine (FSM)
  architecture for CharacterBody2D, custom Resource data modeling, typed signals, and performance guidelines.
---

# Godot 4 & GDScript Programming Skill

## 1. Core Principles
* **Godot 4 Syntax Only**: Never use Godot 3 patterns (`KinematicBody2D`, `yield`, string signals).
* **Strong Static Typing**: Always declare types for variables, parameters, and return types to optimize performance and prevent runtime bugs:
  ```gdscript
  var speed: float = 240.0
  func calculate_damage(base: int, multiplier: float) -> int:
      return int(base * multiplier)
  ```
* **Composition over Inheritance**: Use specialized Child Nodes (`HitboxArea`, `HurtboxArea`, `StateMachine`) rather than monolithic player scripts.

---

## 2. CharacterBody2D Node-Based Finite State Machine (FSM)
Dead Cells requires clean separation between movement states (Idle, Run, Jump, Fall, Roll, AttackCombo).

### Scene Tree Pattern
```text
Player (CharacterBody2D) [player.gd]
├── CollisionShape2D
├── AnimatedSprite2D / Sprite2D
├── StateMachine (Node) [state_machine.gd]
│   ├── Idle (Node) [idle_state.gd]
│   ├── Run (Node) [run_state.gd]
│   ├── Jump (Node) [jump_state.gd]
│   ├── Fall (Node) [fall_state.gd]
│   ├── Roll (Node) [roll_state.gd]
│   └── Attack (Node) [attack_state.gd]
├── HitboxArea (Area2D)
└── HurtboxArea (Area2D)
```

### Base State Interface (`state.gd`)
```gdscript
class_name State
extends Node

@onready var character: CharacterBody2D = owner
var state_machine = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
```

### State Machine Manager (`state_machine.gd`)
```gdscript
class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	var key := target_state_name.to_lower()
	if not states.has(key) or current_state == states[key]:
		return
	if current_state:
		current_state.exit()
	current_state = states[key]
	current_state.enter()
```

---

## 3. Data-Driven Architecture via Custom Resources
For weapons, loot, and enemy stats, use `Resource` instead of hardcoded variables:

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var weapon_name: String = "Rusty Blade"
@export var base_damage: int = 15
@export var attack_cooldown: float = 0.25
@export var attack_range: float = 32.0
@export var knockback_force: float = 180.0
@export var sprite_texture: Texture2D
```
Save as `.tres` files (`res://weapons/rusty_blade.tres`). This allows visual balancing directly in the Godot Inspector.

---

## 4. Signal Safety
Always connect signals using callable references:
```gdscript
# Safe in Godot 4
health_component.health_depleted.connect(_on_health_depleted)

func _on_health_depleted() -> void:
	state_machine.transition_to("death")
```
