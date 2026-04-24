# Implementation Plan: Expand item drop system (Rarity, UI, Interaction)

## Phase 1: Rarity Data Structure & Generation
- [x] Task: Implement Rarity System 7ae2e7c
    - [x] Write Tests: Ensure `Equipment` resource handles rarity and `EquipmentGenerator` correctly scales stats based on rolled rarity.
    - [x] Implement Feature: Update `equipment.gd` with Rarity enum. Update `equipment_generator.gd` to assign rarity and scale stat values/counts accordingly.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Rarity Data Structure & Generation' (Protocol in workflow.md)

## Phase 2: Interactive Pickup & Visuals
- [ ] Task: Implement Interact Action
    - [ ] Write Tests: Verify that an `interact` action is registered in `InputMap`.
    - [ ] Implement Feature: Programmatically add `interact` (Key 'E') to `InputMap` in a global autoload or player's `_ready()`.
- [ ] Task: Update Item Drop Logic
    - [ ] Write Tests: Ensure equipment doesn't auto-collect, but healing items do. Verify pickup on interact input.
    - [ ] Implement Feature: Refactor `item_drop.gd` `_on_body_entered` to only auto-collect healing. Add `_process` or `_input` logic to handle `interact` while player is inside the area for equipment.
    - [ ] Implement Feature: Update item color and point light to match its rarity tier.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Interactive Pickup & Visuals' (Protocol in workflow.md)

## Phase 3: UI Feedback Tooltips
- [ ] Task: Implement Hover Tooltips
    - [ ] Write Tests: Verify tooltip becomes visible when player enters area and hides when leaving/collected.
    - [ ] Implement Feature: Add a `PanelContainer` with `Label`s to `item_drop.tscn`. Update it in `_ready()` with the formatted equipment stats and toggle its visibility in `_on_body_entered` and `_on_body_exited`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: UI Feedback Tooltips' (Protocol in workflow.md)