# HUD System Specification

## Purpose

Define the heads-up display showing health, Furia del Oso cooldown, level info, and checkpoint feedback.

## Requirements

### Requirement: Health Bar

HUD MUST display player HP as a bar. Health bar SHOULD be at the top-left corner. Bar SHOULD show both current and maximum HP. Color: red when healthy, yellow at 50%, red-flashing at 25%.

#### Scenario: Health updates
- GIVEN the player has 3/3 HP
- WHEN the player takes 1 damage
- THEN the health bar updates to show 2/3
- AND the bar color changes from green to yellow

### Requirement: Furia del Oso Indicator

HUD MUST show Furia del Oso ability status: ready (glowing icon) or cooldown (progress circle). Position: top-right corner.

#### Scenario: Ability ready
- GIVEN Furia del Oso is available
- THEN the icon is bright and glowing
- AND tapping the icon activates the ability

#### Scenario: Ability on cooldown
- GIVEN Furia del Oso is on cooldown
- THEN the icon shows a circular progress indicator
- AND the icon is grayed out
- AND the cooldown time is displayed numerically

### Requirement: Level Info

HUD MUST display the current level name. Position: top-center. SHOULD fade in at level start and fade out after 3s.

#### Scenario: Level start
- GIVEN the level loads
- THEN the level name displays at top-center for 3s
- AND fades out

### Requirement: Checkpoint Feedback

When a checkpoint is activated, HUD MUST show visual feedback. SHOULD display a banner or text "Checkpoint saved!" for 2s.

#### Scenario: Checkpoint activation
- GIVEN the player reaches a checkpoint
- THEN "Checkpoint saved!" text displays briefly
- AND a visual indicator (icon) flashes
