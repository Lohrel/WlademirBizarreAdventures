# Specification: Pixel Font Integration

## 1. Overview
The current UI text is hard to read. This track integrates the newly downloaded "Press Start 2P" pixel font across the game's UI elements, specifically focusing on the HUD and item tooltips to improve readability and match the retro aesthetic.

## 2. Core Requirements
- **Font Asset:** Utilize `assets/fonts/PressStart2P-Regular.ttf` as the primary UI font.
- **HUD Update:** Update all `Label`, `ProgressBar`, and `RichTextLabel` elements in `scenes/hud.tscn` to use the new font.
- **Item Drop Tooltip:** Update `scenes/item_drop.tscn` to use the new font for the item name, rarity, stats, and interact prompt.
- **Scaling & Clarity:** Ensure the font sizes are adjusted appropriately (usually multiples of 8 or 16 for pixel fonts) to prevent blurring and maintain crisp edges.
