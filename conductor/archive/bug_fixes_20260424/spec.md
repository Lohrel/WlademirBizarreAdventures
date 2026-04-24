# Specification: Bug Fixes - Light and Enemy AI

## 1. Overview
This track addresses two bugs:
1. The Player's light is missing due to a missing initialization line.
2. The Mummy (and potentially Skeleton) AI casts two attacks simultaneously if hit while telegraphing.

## 2. Core Requirements
- **Player Light:**
  - Add `$PlayerLight.texture = _create_light_texture(256)` back into the `_ready()` function of `scripts/player.gd`.
- **Enemy AI Double Attack:**
  - Ensure the AI does not immediately re-trigger an attack if it takes damage during its telegraphing phase.
  - Move the `_is_charging` flag to the base `Enemy` class (`scripts/enemy.gd`).
  - Modify `_handle_aggressive` in `scripts/enemy.gd` to prevent triggering `_perform_attack()` if `_is_charging` is true.
  - Modify `take_damage` to not override the `current_state` if it is currently in `State.ATTACK`.