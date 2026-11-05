---
name: gaming-ui-ux
description: >-
  User interface and experience design guidelines for 2D Action Roguelikes and Platformers in Godot 4.
  Includes health HUD, cooldown timers, floating damage numbers, gamepad/keyboard hints, and high readability feedback.
---

# Gaming UI/UX for 2D Action Roguelikes

## 1. Core Principles of Roguelike UI
* **Peripheral Readability**: The player is constantly monitoring enemy attacks. Vital stats (HP, Dodge Cooldown) must be legible in peripheral vision without looking away from the character.
* **Responsive Juice**: UI elements should react to in-game impacts (e.g., HP bar shaking and flashing red on taking damage, white ghost health bar depleting with a brief delay).
* **Zero Input Friction**: Support instant gamepad detection and dynamic key prompt swapping (e.g., showing 'X' for Xbox controller or 'E' for Keyboard).

---

## 2. Essential HUD Elements for a Roguevania

### A. Health & Flask/Potion System (Dead Cells style)
* **Dual-Layer Health Bar**:
  * Foreground: Current HP (instant).
  * Background: "Ghost HP" (delayed drop) to communicate exactly how much chunk damage was sustained.
* **Flask Charges**: Distinct pip-based counters rather than plain percentages.

### B. Skill & Dodge Cooldowns
* Circular radial progress overlay or darkened desaturated icon indicating remaining cooldown seconds.
* Flash-pulse when a cooldown finishes so the player knows their dodge/skill is ready.

### C. Floating Damage Numbers & Combat Text
* Critical Hits: Large yellow/orange font with upward pop and scale-bounce.
* Normal Hits: Smaller white font with slight horizontal drift.
* Status Effects (Bleed/Poison): Distinct colors (Red/Green) pulsing over ticks.

---

## 3. Implementation in Godot 4
* Use `CanvasLayer` with layer `10` or higher to decouple UI from world camera coordinates.
* Use `TextureProgressBar` or `ProgressBar` with custom styleboxes for smooth UI rendering.
* Implement UI animations with `Tween` rather than heavy animation players for responsive, lightweight tweens:
  ```gdscript
  func update_health(new_health: int) -> void:
      var tween := create_tween()
      tween.tween_property(hp_bar, "value", new_health, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  ```
