# Implementation Plan: Add Bandit with Knife

## Phase 1: Player Damage-over-Time Setup
- [ ] Task: Restore Poison/Bleed Logic
    - [ ] Write Tests: Verify the player takes periodic damage and visual effects trigger when poisoned/bleeding.
    - [ ] Implement Feature: Re-implement the `apply_poison(total_damage: float, duration: float)` method in `scripts/player.gd`. The method should use a loop with timers to deal ticks of damage and change the player's modulate color temporarily (e.g., red for bleed or green for poison).
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Player Damage-over-Time Setup' (Protocol in workflow.md)

## Phase 2: Bandit AI and Scene
- [ ] Task: Create Bandit AI Script
    - [ ] Write Tests: Verify the bandit moves faster than standard enemies and applies the DoT effect on hit.
    - [ ] Implement Feature: Create `scripts/bandido_faca.gd` inheriting from `Enemy`. Set high `move_speed` and `chase_speed`. Override `_perform_attack` or the hitbox collision logic to call `apply_poison` on the player alongside base damage.
- [ ] Task: Assemble Bandit Scene
    - [ ] Write Tests: Ensure the scene instantiates without errors and has correct nodes.
    - [ ] Implement Feature: Create `scenes/bandido_faca.tscn` using the correct sprite, animation player, and collision shapes.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Bandit AI and Scene' (Protocol in workflow.md)

## Phase 3: Integration
- [ ] Task: Procedural Spawning
    - [ ] Write Tests: Verify the Bandit with Knife spawns in generated rooms.
    - [ ] Implement Feature: Update `scripts/room.gd` to include `bandido_faca.tscn` in the enemy spawn pool with an appropriate spawn chance (e.g., 15%).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Integration' (Protocol in workflow.md)
