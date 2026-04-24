# Specification: Polish Item Drop Tooltip UI

## 1. Overview
This track focuses on a visual overhaul of the item drop tooltip that appears when Wlademir approaches equipment on the ground. The current plain black box will be replaced with a styled, themed panel featuring rich text formatting and clear visual separation.

## 2. Core Requirements
- **Thematic Background:** Update the `StyleBoxFlat` of the `PanelContainer` to a dark, semi-transparent brown/parchment color with a subtle border to fit the ancient Egyptian/Vampire aesthetic.
- **Rich Text Formatting:** Replace standard `Label`s for stats with `RichTextLabel` (or formatted strings) to color-code numbers (e.g., `+15%` in green) and keep stat names (e.g., `Move Speed`) a neutral color.
- **Clearer Layout/Dividers:** Introduce horizontal separators (`HSeparator`) between the item's header (Name & Rarity), the stat list, and the "Interact" prompt at the bottom to improve readability.
