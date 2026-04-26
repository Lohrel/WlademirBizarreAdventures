# Implementation Plan: Add Bandit with Gun

## Phase 1: Bandit Projectile
- [x] Task: Create Bullet Projectile 3e97cd0
    - [x] Write Tests: Verify bullet speed, damage, and collision with player.
    - [x] Implement Feature: Create `scripts/bandido_projectile.gd` and `scenes/bandido_projectile.tscn` (a fast, linear Area2D projectile).
- [x] Task: Conductor - User Manual Verification 'Phase 1: Bandit Projectile' (Protocol in workflow.md)

## Phase 2: Bandit AI Logic
- [x] Task: Implement Burst Fire AI 3be25fa
    - [x] Write Tests: Verify the bandit shoots exactly 12 times with a 0.3s interval and a 4s cooldown.
    - [x] Implement Feature: Create `scripts/bandido_arma.gd` inheriting from `Enemy`. Override `_perform_attack` to handle the burst loop using timers or `await`.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Bandit AI Logic' (Protocol in workflow.md)

## Phase 3: Bandit Scene Assembly
- [x] Task: Create Enemy Scene d5ec567
    - [x] Write Tests: Ensure the scene instantiates without errors and has correct nodes (Hitbox, RayCast, etc.).
    - [x] Implement Feature: Create `scenes/bandido_arma.tscn` linking the script, sprites, collision shapes, and configuring base stats (health, speed, attack range).
- [x] Task: Conductor - User Manual Verification 'Phase 3: Bandit Scene Assembly' (Protocol in workflow.md)

