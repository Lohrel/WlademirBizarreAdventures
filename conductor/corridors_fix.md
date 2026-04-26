# Objective
Refine the Corridor Skeleton layout to strictly use a Hub-Connector-Room grid to prevent parallel corridors. Additionally, restore the "filler door" collision logic in `room.gd` to prevent players from leaving the map through unconnected doors.

# Key Files & Context
- `scripts/level_generator.gd`: Grid layout and spacing.
- `scripts/room.gd`: Collision filler and visual setup.

# Implementation Steps
1. **Hub-Based Skeleton (`level_generator.gd`)**:
   - Update `_generate_map_layout()`.
   - Start the skeleton at `current_hub = Vector2i(1, 1)`.
   - Random walk by stepping exactly 2 units (e.g., to `(3, 1)`, `(1, 3)`).
   - Mark both the `next_hub` and the intermediate `connector` as `{"type": "corridor"}`.
   - This ensures corridors only exist on odd rows/columns, eliminating any possibility of parallel wide corridors.
2. **Room Attachment (`level_generator.gd`)**:
   - Iterate through all marked corridor cells.
   - For each corridor, check adjacent positions. If an adjacent position is `(even, even)`, mark it as a `{"type": "normal"}` room until `max_rooms` is reached.
3. **Collision Fillers (`room.gd`)**:
   - In `setup_room_ext()`, resize and position the 4 static doors (`DoorNorth`, etc.) to match the new 64px and 32px wall thicknesses.
   - In `setup_room()`, re-implement the logic to disable the `CollisionShape2D` of these static doors ONLY IF there is a valid connection (`has_n`, etc.).
   - This ensures that if a room has no neighbor, a physical collision block remains in the 64px gap, preventing the player from leaving the map.

# Verification & Testing
- Run GUT tests to ensure no regressions.
- Verify that corridors are singular and branching (no wide blocks of parallel corridors).
- Confirm that dead-end walls are solid and block the player.