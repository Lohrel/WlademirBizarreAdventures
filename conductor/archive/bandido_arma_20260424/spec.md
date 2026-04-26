# Specification: Add Bandit with Gun (Bandido com Arma)

## 1. Overview
The game needs a new ranged enemy type: the "Bandido com Arma" (Bandit with Gun). This enemy will challenge the player with a rapid-fire burst mechanic, forcing the player to find cover or time their dashes carefully.

## 2. Core Requirements
- **Enemy AI (Base):** Inherits from the base `Enemy` class (`scripts/enemy.gd`).
- **Attack Pattern (Burst Fire):**
  - The bandit fires a burst of **12 projectiles**.
  - There is a **0.3 seconds delay** between each shot within the burst.
  - After firing all 12 shots, the bandit enters a **4-second reload (cooldown)** phase before it can shoot again.
- **Projectile:**
  - Needs a dedicated bullet projectile (faster than the Mummy's fireball, non-explosive, deals moderate damage).
- **Visuals:**
  - Utilizes existing bandit sprites (e.g., `assets/sprites/bandido_arma/`).
  - Clear telegraphing when aiming/reloading.
