---
name: procedural-level-design
description: >-
  Procedural generation algorithms and chunk architecture for 2D platformers and Roguevanias (Dead Cells and Spelunky style).
  Covers random walker graph layouts, room socket matching, critical path verification, and seed management in Godot 4.
---

# Procedural Level Design for 2D Action Platformers

## 1. The Platformer Procedural Dilemma
Unlike top-down roguelikes or dungeon crawlers (where pure random walkers or BSP dungeons work easily), 2D platformers are strictly constrained by:
* **Gravity and Jump Arcs**: A single unjumpable gap breaks the entire run.
* **Verticality & Headroom**: Floating platforms must not block jump clearance.

Therefore, the gold standard (used by *Dead Cells* and *Spelunky*) is **Hybrid Generation**:
1. Handcraft modular room **chunks** (ensuring fun, tested platforming).
2. Use procedural **graph walkers** to stitch rooms together via standardized sockets.

---

## 2. Core Architecture: The Chunk & Socket System

### A. Room Templates (`room_template.tscn`)
Each room is a self-contained scene built with `TileMapLayer` and socket markers:
* Dimensions: Standardized grid size (e.g., 32x18 tiles = 512x288 px at 16x16 tiles).
* Sockets (`Marker2D` nodes):
  * `SocketLeft`, `SocketRight`, `SocketTop`, `SocketBottom`.
  * Metadata flags indicating if the socket is open or sealed.

### B. Room Categorization
* `StartRoom`: Player spawn, no immediate enemy threat.
* `CorridorRoom`: Horizontal transit with minor hazards.
* `VerticalShaft`: Multi-tier climbing rooms with one-way platforms.
* `CombatArena`: Locked room with wave spawner markers and high vertical clearance.
* `TreasureRoom`: Branching off the critical path, holding chests/shrines.
* `ExitRoom`: Teleporter / gate to next biome.

---

## 3. Algorithm: Directed Random Walker with Branching

```
[Start Room (0,0)]
       ↓ (Right)
[Combat Room (1,0)] ──(Up)──> [Treasure Room (1,-1)] (Dead End Branch)
       ↓ (Right)
[Corridor (2,0)]
       ↓ (Down)
[Vertical Shaft (2,1)]
       ↓ (Right)
[Exit Room (3,1)]
```

### Generation Pipeline
1. **Critical Path**: Establish a guaranteed route from Start to Exit using a directed walker (moving Right, Up, or Down, never intersecting).
2. **Branching Paths**: From nodes along the critical path, generate short side branches (1–2 rooms max) terminating in Reward/Shop rooms.
3. **Fill Blanks**: Any unused adjacent grid cells are either left empty (solid wall background) or filled with secret challenge rooms.
4. **Validation Pass**: Ensure all connected sockets match (e.g., a room requiring an exit on the right is only placed adjacent to a room with an entrance on the left).

---

## 4. Seeding & Reproducibility
* Always encapsulate procedural generation with a controllable `RandomNumberGenerator`:
  ```gdscript
  var rng := RandomNumberGenerator.new()
  
  func generate_with_seed(world_seed: int) -> void:
      rng.seed = world_seed
      # All randi/randf calls use rng.randi_range() etc.
  ```
* Exposing the seed enables reproducible bug debugging, daily runs, and player seed-sharing.
