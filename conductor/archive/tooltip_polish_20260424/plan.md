# Implementation Plan: Polish Item Drop Tooltip UI

## Phase 1: Tooltip Visual Overhaul [checkpoint: bd10672]
- [x] Task: Thematic Background and Layout bd10672
    - [x] Write Tests: Ensure the tooltip panel uses the updated thematic stylebox and separators exist.
    - [x] Implement Feature: Modify `scenes/item_drop.tscn` to change the `PanelContainer`'s `StyleBoxFlat` to a dark brown tint. Add `HSeparator` nodes between the header, stats, and interact sections within the `VBoxContainer`.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Tooltip Visual Overhaul' (Protocol in workflow.md)

## Phase 2: Rich Text Formatting for Stats [checkpoint: bd10672]
- [x] Task: Color-Coded Stats bd10672
    - [x] Write Tests: Verify the generated string includes BBCode formatting for stat bonuses.
    - [x] Implement Feature: Update `scenes/item_drop.tscn` by replacing `StatsLabel` with a `RichTextLabel` with BBCode enabled. Update `scripts/item_drop.gd`'s `_setup_tooltip` to format the stats string with color tags (e.g., `[color=green]+15%[/color] Move Speed`).
- [x] Task: Conductor - User Manual Verification 'Phase 2: Rich Text Formatting for Stats' (Protocol in workflow.md)
