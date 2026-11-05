---
name: platformer-spritesheet-gen
description: >-
  Specifications and automated generation pipeline for 2D platformer character and tileset spritesheets.
  Focuses on grid consistency, feet-pivot anchoring, keyframe breakdowns (idle, run, jump, fall, roll, attack combo),
  and hitbox alignment.
---

# 2D Platformer Spritesheet Pipeline & Generation

## 1. Dimensional Standards & Grid Consistency
* **Frame Dimensions**: Use power-of-two square or uniform rectangles (e.g., 32x32 px, 48x48 px, or 64x64 px).
* **Feet-Pivot Anchoring**:
  * In a 2D platformer, the pivot point (`offset` or collision base) **must always align at the bottom-center** of the frame (between the character's feet).
  * If the pivot shifts during an animation, the character will visibly jitter or sink into the ground.
* **Canvas Headroom**: Ensure sufficient transparent padding at the top and sides for sword swings, jumps, and dust particles without cropping the sprite.

---

## 2. Animation Keyframe Breakdown (Action Platformer)

| Animation | Frame Count | Framerate | Key Poses & Notes |
| :--- | :---: | :---: | :--- |
| **Idle** | 4–6 | 6–8 FPS | Subtle breathing, sword held ready, slight vertical shoulder bob. |
| **Run** | 6–8 | 10–12 FPS | Contact -> Down -> Passing -> Up -> Contact. Forward lean of ~10°. |
| **Jump Startup** | 1–2 | 12 FPS | Anticipation crouch (1 frame) -> Stretch upward takeoff. |
| **Jump Peak / Fall** | 2 | 8 FPS | Apex pose (tucked knees) -> Downward fall pose with trailing hair/cape. |
| **Roll / Dodge** | 5–7 | 14 FPS | Fast tuck into circular ball, forward velocity stretch, smooth recovery roll. |
| **Attack 1 (Slash)** | 4 | 12–14 FPS | Windup (1 frame) -> Massive forward slash arc -> Brief follow-through. |
| **Attack 2 (Thrust)** | 4 | 12–14 FPS | Low preparation -> Forward lunging thrust -> Return. |
| **Hit / Hurt** | 2–3 | 10 FPS | Knockback recoil, white/red flash posture. |

---

## 3. Automated Procedural Sprite Generation via Python (Pillow)
For rapid prototype testing, the AI can generate colored silhouette spritesheets directly:
* Use distinct geometric layers (torso, head, weapon, limbs) so orientation is unmistakable.
* Export as PNG with transparent background (`RGBA`).
* Match Godot's `SpriteFrames` resource layout or uniform grid for easy import into `AnimatedSprite2D`.

---

## 4. Hitbox & Hurtbox Synchronization in Godot
* Use `AnimationPlayer` or call-method tracks on `AnimatedSprite2D` frame changes to enable/disable the `CollisionShape2D` of `HitboxArea` only on the active damage frames of the attack.
* Never leave a hitbox enabled during windup or recovery frames.
