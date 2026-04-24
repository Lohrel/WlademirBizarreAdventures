# Specification: Implement 5-slot equipment inventory

## 1. Overview
The game will feature a simple 5-slot equipment inventory for Wlademir. The player can equip items in the following slots: Boots, Gloves, Tunic, Hat, and Ring. Items drop randomly with procedurally generated stats that scale with the dungeon's floor level.

## 2. Core Requirements
- **Inventory Structure:** A robust system to manage the 5 specific slots.
- **Procedural Item Generation:** 
  - Stats must scale with the floor level (e.g., Level 1 grants 1% to 6% boosts).
  - Specific slots provide specific stat boosts:
    - **Boots:** Movement Speed, Quicksand Speed, Dash Mana Cost reduction, Dash Cooldown reduction.
    - **Gloves:** Base Attack Damage, Critical Hit Chance, Attack Range.
    - **Tunic:** Max Health, Health Regeneration, Max Mana.
    - **Hat:** Rare drop; Reduces Sunlight Damage.
    - **Ring:** Special drop; Provides new skills or significant modifiers.
- **Player Stats Hookup:** Equipping and unequipping items must dynamically and safely recalculate Wlademir's active stats.
- **UI Representation:** The HUD must display the 5 slots, showing currently equipped items.
- **Item Drops:** The existing item drop system must be updated to spawn these equipment pieces.