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

## 2. Hit-Flash Shader
When an entity takes damage, flash its sprite completely white for 0.08s:
```glsl
// hit_flash.gdshader
shader_type canvas_item;

uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	if (active) {
		COLOR = vec4(flash_color.rgb, original_color.a);
	} else {
		COLOR = original_color;
	}
}
```

---

## 3. Audio Bus Routing
Configure 3 primary audio buses in Godot's audio panel:
1. `Master`
   ├── `BGM` (Music)
   └── `SFX` (Sound Effects)
        ├── `CombatSFX` (Swords, hits, dodge whoosh)
        └── `EnvironmentSFX` (Footsteps, ambient cave drip)

* Attach `AudioStreamPlayer2D` with slight pitch randomization (`pitch_scale = randf_range(0.92, 1.08)`) on weapon impacts so repeated swings never sound robotic.
