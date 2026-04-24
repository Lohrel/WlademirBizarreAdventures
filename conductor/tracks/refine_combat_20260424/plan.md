# Implementation Plan: Refine Player combat mechanics and Enemy AI interactions

## Phase 1: Player Movement and Melee Foundation [checkpoint: b367e30]
- [x] Task: Set up unit testing framework for Godot GDScript (if not present). ddc9bdf
- [x] Task: Refine Player Dash 8fafab8
    - [x] Write Tests: Dash speed, distance, and invincibility frames.
    - [x] Implement Feature: Update `player.gd` and `player.tscn` to adjust dash mechanics.
- [x] Task: Polish Melee Attack (Claws) 423c27a
    - [x] Write Tests: Hitbox active frames and damage calculation.
    - [x] Implement Feature: Update claw attack animations, hitboxes, and particle effects.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Player Movement and Melee Foundation' (Protocol in workflow.md)

## Phase 2: Enemy AI and Telegraphing
- [x] Task: Refine Mummy AI 14e4511
    - [x] Write Tests: Mummy detection radius and projectile firing rate.
    - [x] Implement Feature: Update `mumia.gd` for clearer attack tells and smoother movement.
- [x] Task: Refine Skeleton AI d877b75
    - [x] Write Tests: Skeleton melee range and engagement behavior.
    - [x] Implement Feature: Update `skeleton.gd` to improve pathfinding toward the player.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Enemy AI and Telegraphing' (Protocol in workflow.md)

## Phase 3: Combat Integration and Polish
- [ ] Task: Damage and Resource Hookup
    - [ ] Write Tests: Player taking damage, enemy taking damage, health updates.
    - [ ] Implement Feature: Ensure `hud.tscn` accurately reflects combat state changes.
- [ ] Task: Game Feel and Hit Stop
    - [ ] Write Tests: Hit stop timing triggers.
    - [ ] Implement Feature: Add subtle hit stop (frame freeze) and camera shake on critical hits.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Combat Integration and Polish' (Protocol in workflow.md)