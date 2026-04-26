# Implementation Plan: Add Bandit with Gun

## Phase 1: Bandit Projectile
- [ ] Task: Create Bullet Projectile
    - [ ] Write Tests: Verify bullet speed, damage, and collision with player.
    - [ ] Implement Feature: Create `scripts/bandido_projectile.gd` and `scenes/bandido_projectile.tscn` (a fast, linear Area2D projectile).
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Bandit Projectile' (Protocol in workflow.md)

## Phase 2: Bandit AI Logic
- [ ] Task: Implement Burst Fire AI
    - [ ] Write Tests: Verify the bandit shoots exactly 12 times with a 0.3s interval and a 4s cooldown.
    - [ ] Implement Feature: Create `scripts/bandido_arma.gd` inheriting from `Enemy`. Override `_perform_attack` to handle the burst loop using timers or `await`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Bandit AI Logic' (Protocol in workflow.md)

## Phase 3: Bandit Scene Assembly
- [ ] Task: Create Enemy Scene
    - [ ] Write Tests: Ensure the scene instantiates without errors and has correct nodes (Hitbox, RayCast, etc.).
    - [ ] Implement Feature: Create `scenes/bandido_arma.tscn` linking the script, sprites, collision shapes, and configuring base stats (health, speed, attack range).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Bandit Scene Assembly' (Protocol in workflow.md)
