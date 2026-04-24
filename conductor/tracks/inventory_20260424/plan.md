# Implementation Plan: Implement 5-slot equipment inventory

## Phase 1: Item Data Structure and Generation [checkpoint: 12185d5]
- [x] Task: Define Equipment Item Structure 079389b
    - [x] Write Tests: Ensure Item Resource/Class stores stats and slot type correctly.
    - [x] Implement Feature: Create `equipment.gd` (Resource) defining slot enum and stat dictionary.
- [x] Task: Procedural Generation Logic 079389b
    - [x] Write Tests: Ensure RNG generates stats within expected ranges based on level and slot constraints.
    - [x] Implement Feature: Create a generation script/autoload to spawn equipment with randomized stats tailored to their slot (Boots, Gloves, Tunic, Hat, Ring).
- [x] Task: Conductor - User Manual Verification 'Phase 1: Item Data Structure and Generation' (Protocol in workflow.md)

## Phase 2: Player Inventory and Stat Hookup [checkpoint: c1a5fe0]
- [x] Task: Inventory System 642479c
    - [x] Write Tests: Verify equipping, unequipping, and replacing items in the 5 slots.
    - [x] Implement Feature: Add an `Inventory` system to `player.gd` managing the 5 specific slots.
- [x] Task: Dynamic Stat Recalculation 642479c
    - [x] Write Tests: Verify player stats accurately reflect equipped item bonuses and base values.
    - [x] Implement Feature: Refactor player attributes to calculate final values dynamically from base + equipment modifiers.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Player Inventory and Stat Hookup' (Protocol in workflow.md)

## Phase 3: Drops and UI Integration
- [ ] Task: Equipment Drops
    - [ ] Write Tests: Verify enemies drop equipment and the player can pick them up.
    - [ ] Implement Feature: Update `item_drop.tscn` to handle equipment and update enemy loot tables.
- [ ] Task: Inventory UI
    - [ ] Write Tests: Verify UI slots correctly display equipped items.
    - [ ] Implement Feature: Update `hud.tscn` to visually represent the 5 equipment slots and allow basic interaction (viewing/equipping).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Drops and UI Integration' (Protocol in workflow.md)