---
name: godot-debugging
description: >-
  Godot 4 debugging workflows, headless automated syntax checks via CLI, runtime inspection,
  profiler metrics, handling cyclic references, and memory cleanup.
---

# Godot 4 Debugging & Testing Workflows

## 1. Headless CLI Syntax & Compilation Check
Before launching the game or giving code to the user, always validate all scripts, autoloads, `@tool` plugins, `.tres` resources, and scene dependencies using the Windows console binary (`Godot_v4.7.2-stable_win64_console.exe`):

```powershell
# Load full editor headless, resolve all scripts/scenes/resources, and exit cleanly
& "C:\Tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --quit --path . 2>&1
```
Do **not** use the legacy `--check-only` flag without `--script`: on Windows GUI/headless setups it skips full project/autoload compilation and can report exit code `0` silently despite broken scripts. `--editor --quit` on the console binary catches every `SCRIPT ERROR`, `Parse Error`, and missing resource dependency.

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
