# Implementation Plan: Bug Fixes - Light and Enemy AI

## Phase 1: Player Light Fix
- [ ] Task: Fix Player Light Initialization
    - [ ] Write Tests: Ensure player light has a valid texture.
    - [ ] Implement Feature: Update `scripts/player.gd` `_ready()` to include light texture creation.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Player Light Fix' (Protocol in workflow.md)

## Phase 2: Enemy AI Double Attack Fix
- [ ] Task: Prevent Double Attacks
    - [ ] Write Tests: Hit enemy during attack preparation and assert it doesn't double cast.
    - [ ] Implement Feature: Move `_is_charging` to base `Enemy`, guard `_handle_aggressive`, and ignore state resets on hit if in `State.ATTACK`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Enemy AI Double Attack Fix' (Protocol in workflow.md)