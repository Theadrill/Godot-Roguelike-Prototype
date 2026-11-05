---
name: gamedesign-roguelike
description: >-
  Game feel and combat mechanics design for fast-paced 2D Roguevanias (inspired by Dead Cells).
  Covers hitstop/hitfreeze, coyote time, jump buffering, invulnerability frames (i-frames),
  animation canceling, attack telegraphing, and input queuing.
---

# Game Design & Game Feel for Action Roguelikes

## 1. The "Forgiving Rules" Philosophy
As proven by Dead Cells and Celeste: *"Make the game do what the player wants to do, rather than strictly what they pressed."*

---

## 2. Platforming Game Feel Pillars

### A. Coyote Time (Ledge Forgiveness)
* **Rule**: When the player runs off a ledge, allow jumping for **0.10s to 0.15s** (approx. 6–9 frames at 60 FPS).
* **Godot implementation**:
  * Track `coyote_timer: float = 0.0`.
  * If `is_on_floor()`, `coyote_timer = coyote_duration`.
  * In the air, decrement timer. Jump is valid if `coyote_timer > 0.0`.

### B. Jump Buffering (Queued Execution)
* **Rule**: If the player presses the jump button within **0.12s** before touching the ground, buffer the input and execute the jump the exact frame they land.
* **Godot implementation**:
  * Track `jump_buffer_timer: float = 0.0`.
  * When `Input.is_action_just_pressed("jump")`, set `jump_buffer_timer = buffer_duration`.
  * When touching the floor with `jump_buffer_timer > 0`, trigger jump immediately and consume the buffer.

### C. Variable Jump Height
* Tapping jump gives a short hop; holding jump sustains upward velocity until a maximum threshold or button release.

---

## 3. Combat Weight & Visceral Impact

### A. Hitstop / Hitfreeze
* **Rule**: The exact frame an attack hits, pause the target (or the entire scene) for a micro-fraction of a second:
  * Light attack: **0.03s - 0.05s** (2–3 frames).
  * Heavy/Critical attack: **0.08s - 0.12s** (5–7 frames).
* This provides instant tactile weight to weapon swings.

### B. Dodge Roll & Invincibility Frames (i-frames)
* Standard roll duration: ~0.4s to 0.5s.
* i-frames active during the first 60–70% of the roll.
* Allows phasing through enemies and projectiles.
* Brief recovery window at the tail end to prevent endless spamming.

### C. Input Canceling & Priority
1. **Dodge/Roll** has highest priority: Can cancel startup and recovery of attacks.
2. **Jump** can cancel ground recovery.
3. **Attack Combo**: Consecutive attacks chain together if pressed during the active/recovery window of the previous strike.

### D. Enemy Attack Telegraphing
* Every enemy attack must have a distinct wind-up visual cue (e.g., bright yellow/red exclamation or flash) and audio indicator, giving the player 0.3s–0.6s to react with a dodge or jump.
