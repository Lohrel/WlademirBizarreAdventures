# Implementation Plan: Pixel Font Integration

## Phase 1: Font Registration and HUD Update
- [ ] Task: Apply Font to HUD
    - [ ] Write Tests: Ensure HUD elements (like labels) are using a valid custom font.
    - [ ] Implement Feature: Update `scenes/hud.tscn` to assign `assets/fonts/PressStart2P-Regular.ttf` to `theme_override_fonts/font` for relevant text elements, adjusting font sizes (e.g., 8px) for crisp rendering.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Font Registration and HUD Update' (Protocol in workflow.md)

## Phase 2: Tooltip Font Update
- [ ] Task: Apply Font to Item Tooltips
    - [ ] Write Tests: Ensure tooltip text nodes use the custom font.
    - [ ] Implement Feature: Update `scenes/item_drop.tscn` to assign the new pixel font to the Name, Rarity, Stats (`RichTextLabel`), and Interact `Label`s.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Tooltip Font Update' (Protocol in workflow.md)
