---
name: platformer-leveldesign
description: >-
  Level design metrics, spatial constraints, chunk-based procedural layout, and combat arena
  pacing for 2D platformers and Roguevanias in Godot 4.
---

# 2D Platformer Level Design & Chunk Architecture

## 1. Metrics & Spatial Ratios
Never place tiles arbitrarily; every platform distance and ceiling height must be calibrated to the player's movement metrics.

### Golden Ratio of Player Metrics
* **Standard Tile Size**: 16x16 px or 32x32 px.
* **Character Bounding Box**: Typically 2 tiles wide x 2 to 3 tiles tall.
* **Max Jump Height ($H_{max}$)**: Expressed in tiles (e.g., 3.5 tiles). Ceiling clearance must always be at least $H_{max} + 1$ tile to prevent head-bumping.
* **Max Jump Distance ($D_{max}$)**: Expressed in tiles (e.g., 5 tiles at top run speed). Standard comfortable gaps should be 3–4 tiles; 5 tiles is a precision challenge.
* **Roll Clearance**: A 1.5-tile tall gap allows the player to roll under obstacles, creating alternate paths.

---

## 2. Combat Arena Design (Roguevania Style)
Unlike linear runners, a Roguevania alternates between transit corridors and locked combat rooms.

* **Vertical Tiering**: Always provide 3 distinct vertical levels in a combat arena:
  1. *Floor Level*: For ground melee duels.
  2. *Mid-tier Floating Platforms*: One-way platforms (`CollisionShape2D` with `one_way_collision = true`) to escape ground traps.
  3. *High Ledges*: Safe drop-down vantage points.
* **Escape Routes**: Ensure the player is never trapped in a dead corner without an aerial escape path (at least 1.5x jump height vertical headroom).

---

## 3. Procedural Chunk-Based Layout
Pure random generation creates unplayable dead ends in platformers. Use **Prefab Chunks with Marker2D Sockets**:

```
[Level Generator]
 ├── Loads room chunks: room_start.tscn, room_combat_a.tscn, room_corridor.tscn, room_exit.tscn
 ├── Sockets:
 │    ├── DoorLeft (Marker2D)
 │    └── DoorRight (Marker2D)
 └── Connects sockets sequentially, verifying valid pathing to exit and loot rooms.
```

## 4. Godot 4 TileMapLayer Best Practices
* Use separate `TileMapLayer` nodes for:
  * `BackgroundLayer` (no collision, parallax or darker modulate)
  * `TerrainLayer` (with physics collision shapes configured in TileSet)
  * `ForegroundLayer` (decorative foliage / pillars passing in front of player)
* Enable `y_sort_enabled` where depth layering is required.
