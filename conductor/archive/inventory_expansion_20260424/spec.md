# Specification: Expand item drop system (Rarity, UI, Interaction)

## 1. Overview
This track expands the inventory system by adding rarity tiers to procedurally generated equipment, requiring manual interaction ('E' key) to pick up items, and displaying a UI tooltip with the item's stats when the player is near it.

## 2. Core Requirements
- **Rarity System:**
  - Add an enum for Rarity: Common (White), Uncommon (Green), Rare (Blue), Epic (Purple), Legendary (Gold).
  - Modify `EquipmentGenerator` so items roll for rarity. Higher rarities provide larger stat boosts and multiple stats.
- **Visuals:**
  - The drop's `self_modulate` color and particle color should reflect its rarity tier.
- **Interactive Pickup:**
  - Equipment items no longer auto-equip on touch.
  - The player must press a dedicated "Interact" key ('E', mapped to action `interact`) while inside the item's `Area2D` to pick it up.
  - Standard healing drops will continue to auto-collect.
- **UI Feedback (Tooltips):**
  - When the player enters an equipment drop's area, a UI tooltip (e.g., `Label` or `PanelContainer`) should appear above the item displaying its name, rarity, and stat bonuses.
  - The tooltip disappears when the player leaves the area or picks up the item.