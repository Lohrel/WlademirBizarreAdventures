# Implementation Plan: Bug Fixes - Light and Enemy AI

## Phase 1: Player Light Fix [checkpoint: b307168]
- [x] Task: Fix Player Light Initialization b307168
    - [x] Write Tests: Ensure player light has a valid texture.
    - [x] Implement Feature: Update `scripts/player.gd` `_ready()` to include light texture creation.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Player Light Fix' (Protocol in workflow.md)

## Phase 2: Enemy AI Double Attack Fix [checkpoint: b307168]
- [x] Task: Prevent Double Attacks b307168
    - [x] Write Tests: Hit enemy during attack preparation and assert it doesn't double cast.
    - [x] Implement Feature: Move `_is_charging` to base `Enemy`, guard `_handle_aggressive`, and ignore state resets on hit if in `State.ATTACK`.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Enemy AI Double Attack Fix' (Protocol in workflow.md)