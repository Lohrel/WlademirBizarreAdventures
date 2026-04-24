# Initial Concept
Wlademir Bizarre Adventures is a procedural atmospheric dungeon crawler developed in Godot 4. The player controls Wlademir, an ancient vampire seeking a cure for his curse in forgotten Egyptian ruins. The core loop involves navigating procedurally generated rooms, solving environmental puzzles with physics objects, and avoiding dynamic sunlight that poses a deadly threat.

# Product Guide

## Target Audience and Gameplay Feel
The game targets players who enjoy fast-paced, action-oriented gameplay requiring quick reflexes. While planning and utilizing shadows is necessary, combat and movement are aggressive and responsive.

## Progression System
The game operates as a Strict Roguelike. Each run is a fresh attempt with permanent death. Players must rely on their accumulated skill and knowledge of the dungeon's mechanics rather than meta-progression upgrades to survive.

## Combat Mechanics
Wlademir's combat toolkit is versatile, allowing for multiple approaches:
- **Melee Focus:** Close-quarters combat utilizing vampiric claws and quick dashes.
- **Ranged/Magic:** Projectile attacks utilizing dark magic to strike from a distance.
- **Stealth/Evasion:** Utilizing shadows and environmental cover to bypass enemies entirely when confrontation is too risky.

## Core Resource Management
Survival hinges on managing multiple critical resources simultaneously:
- **Health and Mana:** Essential for combat and utilizing magical abilities.
- **Inventory & Equipment:** A 5-slot equipment system (Boots, Gloves, Tunic, Hat, Ring) that allows players to customize Wlademir's build.
  - **Procedural Loot:** Items drop with randomized, level-scaled stats.
  - **Strategic Boosts:** Different slots provide specific advantages, such as movement speed, attack damage, or sunlight resistance.
- **Time/Sunlight:** A ticking clock mechanic where spending too much time results in the dungeon ceiling collapsing, flooding all rooms with lethal sunlight.
