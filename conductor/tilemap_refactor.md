# Objective
Refactor the level generation and room structure to utilize a 16x16 tile-based grid system and fully integrate a `TileMap` node for rendering floors and walls instead of using `ColorRect`.

# Key Files & Context
- `scripts/level_generator.gd`: Responsible for assigning room sizes. Currently uses arbitrary pixel dimensions (e.g., 300, 400).
- `scenes/room.tscn`: Contains the visual and physical structure of a room. Currently uses `ColorRect`s for visuals and manual `RectangleShape2D`s for collisions.
- `scripts/room.gd`: The script that dynamically positions walls and floors based on the room size.
- `scenes/interactive_door.tscn` & `scripts/interactive_door.gd`: The doors connecting rooms, which need to be aligned with the new tile dimensions.
- `assets/sprites/tile_map/tilemap_teste.tres`: The target TileSet resource to be used.

# Implementation Steps
1. **Update Math in `LevelGenerator`**: 
   - Modify the `col_widths` and `row_heights` logic in `_generate_map_layout()`. Instead of picking from `[300, 400, 600, 800]`, randomly select dimensions in tiles (e.g., 16, 24, 32).
   - Multiply the selected tile counts by 16 to determine the pixel dimensions of the rooms. Max dimensions will be 16 tiles wide x 32 tiles high (256x512 pixels).
2. **Integrate `TileMap` in `room.tscn`**:
   - Remove the `Floor` and `Walls` nodes containing `ColorRect`s.
   - Add a `TileMap` node to the scene, configured with `tilemap_teste.tres`.
3. **Programmatic Drawing in `room.gd`**:
   - Rewrite `setup_room_ext` to iterate through the room's tile bounds and draw the room using the `TileMap.set_cell()` method.
   - **Floor**: Fill the inner area with atlas coordinate `Vector2i(1, 3)`.
   - **North/South Walls**: Draw 2 tiles thick. The top row uses `Vector2i(0, 1)` and the inner visible row uses `Vector2i(1, 1)`.
   - **East/West Walls**: Draw 1 tile thick using `Vector2i(0, 1)`.
   - Leave a 2-tile wide gap (32px) for the doors at the cardinal directions based on the `has_n`, `has_s`, `has_e`, `has_w` parameters.
4. **Collision and Occlusion Adjustments**:
   - Add a physical layer to the TileSet or manually adjust the `RectangleShape2D` nodes to match the new 2-tile thick N/S walls and 1-tile thick E/W walls.
   - Adjust the `LightOccluder2D` shapes to snap to the tile boundaries.
5. **Adjust Procedural Content Boundaries**:
   - Update `_spawn_procedural_content()` margins so pillars, boxes, enemies, and traps do not spawn inside the thicker walls.
6. **Doors Alignment**:
   - Update the positioning of `DoorNorth`, `DoorSouth`, `DoorEast`, `DoorWest` to align with the new gap coordinates.
   - Ensure the `InteractiveDoor` bounds match the 32x16 pixel (2x1 tiles) specification.

# Verification & Testing
- Start the game and observe the level generation.
- Ensure the floor and walls are rendered with the correct tiles.
- Verify collisions on all walls and that the player can pass through the doors.
- Confirm enemies and objects spawn within the playable area of the room without clipping into the walls.