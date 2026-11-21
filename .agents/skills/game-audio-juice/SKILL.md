---
name: game-audio-juice
description: >-
  Juice, feedback systems, screen shake (trauma-based), particle hits, flash shaders, and audio buses
  for visceral 2D combat impact in Godot 4.
---

# Game Juice, Screen Shake & Combat Audio

## 1. Trauma-Based Screen Shake
Never use linear random offsets for camera shake; use a decaying squared trauma model:
* `trauma = clamp(trauma + amount, 0.0, 1.0)`
* `shake_offset = max_offset * (trauma * trauma) * noise`
* In `_process(delta)`: `trauma = max(0.0, trauma - decay_rate * delta)`.
* This ensures heavy explosions shake violently but settle down smoothly.

---

## 2. Unified Hit-Flash & Pixel Dissolve Shader (Mobile TBDR Optimized)
Unify **Hit Flash** and **Pixel Dissolve** inside a single `ShaderMaterial` ([`res://src/shaders/hit_flash.gdshader`](../../src/shaders/hit_flash.gdshader)) organized with `group_uniforms hit_flash` and `group_uniforms dissolve`:

1. Read `vec4 base_color = COLOR;` in `fragment()` so both `Polygon2D` vertex colors, `Sprite2D`/`AnimatedSprite2D` textures, and `modulate` are preserved cleanly.
2. Gate `noise_texture` sampling behind `if (dissolve_amount > 0.0)` so combat has zero extra texture-fetch overhead while actors are alive, and sample using local pixel coordinates (`floor(v_local_pos)`) for crisp 1:1 pixel-art grains without mixels.
3. Prefer `final_alpha = 0.0` instead of `discard` when dissolving pixels so mobile TBDR GPUs retain *Early-Z* optimizations.
4. Instantiate `ShaderMaterial.new()` per actor instance in `_ready()` so flashing or dissolving one enemy never mutates siblings.

---

## 3. Audio Bus Routing
Configure 3 primary audio buses in Godot's audio panel:
1. `Master`
   ├── `BGM` (Music)
   └── `SFX` (Sound Effects)
        ├── `CombatSFX` (Swords, hits, dodge whoosh)
        └── `EnvironmentSFX` (Footsteps, ambient cave drip)

* Attach `AudioStreamPlayer2D` with slight pitch randomization (`pitch_scale = randf_range(0.92, 1.08)`) on weapon impacts so repeated swings never sound robotic.
