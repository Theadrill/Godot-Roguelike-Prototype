---
name: godot-debugging
description: >-
  Godot 4 debugging workflows, headless automated syntax checks via CLI, runtime inspection,
  profiler metrics, handling cyclic references, and memory cleanup.
---

# Godot 4 Debugging & Testing Workflows

## 1. Headless CLI Syntax & Compilation Check
Before launching the game or giving code to the user, the AI can validate all scenes and scripts via terminal:

```powershell
# Check for compile errors and invalid resource paths without opening a GUI window
godot --headless --check-only --path .
```
If errors are present, Godot exits with an error code and prints exact line numbers and syntax issues to stderr.

---

## 2. Assertion & Defensive Programming
Use `assert()` statements in debug builds to catch null references immediately:
```gdscript
func equip_weapon(weapon: WeaponData) -> void:
	assert(weapon != null, "Cannot equip a null weapon!")
	current_weapon = weapon
```

---

## 3. Remote Scene Tree & Debugger in Editor
* When running the game, switch from "Local" to "Remote" in the Scene dock to inspect live node properties, duplicate nodes, or check if enemies are properly removed from the tree.
* **Visible Collision Shapes**:
  * In the Godot top menu: `Debug` -> `Visible Collision Shapes`.
  * Crucial for verifying that hitboxes, hurtboxes, and terrain colliders line up with visual sprites.

---

## 4. Preventing Memory Leaks
* **Nodes**: Always use `queue_free()` instead of `free()` to avoid deleting objects while physics or signal callbacks are mid-execution.
* **Signals**: Godot 4 auto-disconnects signals when target objects are freed, but disconnecting explicitly in `exit()` methods of states prevents dangling references.
* **Orphan Nodes**: Check `Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)` to ensure entities (bullets, particles, destroyed enemies) are not leaking in memory.
