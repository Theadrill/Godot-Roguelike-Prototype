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

---

## 5. GDScript VM, Mobile & Pixel-Art Performance Guidelines

* **`StringName` (`&"..."`) in Hot Loops (`_process` / `_physics_process`):** Always use `StringName` literals (`&"jump"`, `&"move_left"`, `&"idle"`) for `Input.is_action_*`, `Input.get_axis`, animation names, and group queries in per-frame paths to avoid repeated `String` allocation and hashing.
* **No Tree Searches Per Frame & AI Perception Throttling:** Never call `get_nodes_in_group()`, `find_child()`, or path-string `get_node()` inside `_physics_process`. Cache the `Player` reference in `BaseEnemy` and throttle heavy patrol perception/raycasts (`0.10s–0.15s` with randomized initial jitter in `_ready()`) rather than scanning at 60 Hz.
* **Safe `VisibleOnScreenEnabler2D` Usage:** In large biomes, configure an enlarged `rect` (at least `720x400` for a `480x270` viewport) or restrict hibernation to `Patrol` so active `Chase` states and off-screen `respawn_timer` countdowns never freeze prematurely.
* **Pixel Art Import vs. `VRAM Compressed` & 60 Hz Physics:** Low-res pixel art (`83x62` / `480x270`) **must** remain `compress/mode=0` (`Lossless`) with `mipmaps/generate=false` — never enable `VRAM Compressed` (ETC2/ASTC) on pixel-art spritesheets, which introduces 4x4 block artifacts. Keep `Physics Ticks per Second = 60` for tight parry, coyote-time, and corner-climb precision.
* **Targeted Object Pooling:** Reserve object pooling for high-frequency, simple-state objects (floating damage numbers in bursts, repetitive particle decals, or bullet-hell rooms) instead of complex stateful combat projectiles.
