# Implementation Plan: Refine Player combat mechanics and Enemy AI interactions

## Phase 1: Player Movement and Melee Foundation
- [x] Task: Set up unit testing framework for Godot GDScript (if not present). ddc9bdf
- [x] Task: Refine Player Dash 8fafab8
    - [x] Write Tests: Dash speed, distance, and invincibility frames.
    - [x] Implement Feature: Update `player.gd` and `player.tscn` to adjust dash mechanics.
- [~] Task: Polish Melee Attack (Claws)
    - [ ] Write Tests: Hitbox active frames and damage calculation.
    - [ ] Implement Feature: Update claw attack animations, hitboxes, and particle effects.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Player Movement and Melee Foundation' (Protocol in workflow.md)

## Phase 2: Enemy AI and Telegraphing
- [ ] Task: Refine Mummy AI
    - [ ] Write Tests: Mummy detection radius and projectile firing rate.
    - [ ] Implement Feature: Update `mumia.gd` for clearer attack tells and smoother movement.
- [ ] Task: Refine Skeleton AI
    - [ ] Write Tests: Skeleton melee range and engagement behavior.
    - [ ] Implement Feature: Update `skeleton.gd` to improve pathfinding toward the player.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Enemy AI and Telegraphing' (Protocol in workflow.md)

## Phase 3: Combat Integration and Polish
- [ ] Task: Damage and Resource Hookup
    - [ ] Write Tests: Player taking damage, enemy taking damage, health updates.
    - [ ] Implement Feature: Ensure `hud.tscn` accurately reflects combat state changes.
- [ ] Task: Game Feel and Hit Stop
    - [ ] Write Tests: Hit stop timing triggers.
    - [ ] Implement Feature: Add subtle hit stop (frame freeze) and camera shake on critical hits.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Combat Integration and Polish' (Protocol in workflow.md)