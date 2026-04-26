# Objective
Refactor level generation to use a "Corridor Skeleton" approach where a network of corridors is generated first, and rooms branch off as mostly dead-end attachments, allowing a single corridor network to connect multiple rooms.

# Key Files & Context
- `scripts/level_generator.gd`: Controls the grid generation algorithm and size allocation.

# Implementation Steps
1. **Generate Corridor Skeleton (`level_generator.gd`)**:
   - Replace the current random walk in `_generate_map_layout()`.
   - Start with a corridor at `Vector2i(1, 1)` (an odd coordinate to ensure it's a corridor hub/connector).
   - Perform a random walk for a set number of steps (e.g., `max_rooms * 2`), marking every visited cell as `{"type": "corridor"}`.
   - This creates a continuous, potentially branching and looping network of corridors.
2. **Attach Rooms (`level_generator.gd`)**:
   - Iterate through all generated corridor cells.
   - For each corridor cell, check its 4 orthogonal neighbors.
   - If a neighbor is empty AND its coordinates are `(even, even)` (ensuring it falls on a Room-sized column/row), there is a chance (e.g., 50%) to spawn a room (`{"type": "normal"}`).
   - Continue attaching rooms until `rooms_created` reaches `max_rooms`.
   - Ensure at least one room is spawned. If the loop finishes and we need more, force-spawn them on available `(even, even)` spots next to corridors.
3. **Designate Special Rooms (`level_generator.gd`)**:
   - Collect all positions marked as `normal`.
   - Pick the first one as `{"type": "start"}`.
   - Pick the one furthest from the start room as `{"type": "boss"}`.
4. **Update Grid Sizing Rules (`level_generator.gd`)**:
   - Update the sizing rules to dynamically check if a column/row actually contains a room.
     - `col_widths[pos.x]`: `16 * 32` if any room exists in column `x`, else `4 * 32`.
     - `row_heights[pos.y]`: `rand([16, 24, 32]) * 32` if any room exists in row `y`, else `6 * 32`.

# Verification & Testing
- Run the game and observe the layout.
- Verify that multiple rooms attach to the corridor network but rarely to each other.
- Confirm corridors have dynamic widths/heights based on whether they share a column/row with a room.