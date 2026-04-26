# Specification: Add Bandit with Knife (Bandido com Faca)

## 1. Overview
The game needs a new fast melee enemy type: the "Bandido com Faca" (Bandit with Knife). This enemy will challenge the player with high-speed chases and attacks that inflict bleeding damage over time, acting similarly to the poison dart mechanic.

## 2. Core Requirements
- **Enemy AI (Base):** Inherits from the base `Enemy` class (`scripts/enemy.gd`).
- **Attributes:**
  - High movement and chase speed (faster than Skeletons and Mummies).
  - Melee attack range.
- **Attack Pattern (Bleeding/Poison):**
  - Upon successful melee hit, applies a damage-over-time effect to the player (Bleeding/Poison).
  - Restores the `apply_poison` method to `scripts/player.gd` to handle the DoT effect.
- **Visuals:**
  - Utilizes existing bandit knife sprites (e.g., `assets/sprites/bandido_faca/`).
  - Clear telegraphing before lunging.
