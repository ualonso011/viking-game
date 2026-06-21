# Touch Controls Specification

## Purpose

Define Android touch input system: virtual buttons for movement, jump, attacks, and dash. Must work without keyboard.

## Requirements

### Requirement: Virtual Buttons

The system MUST render touch buttons on screen: directional pad (left/right), jump, light attack, heavy attack, dash. Buttons SHOULD be large (min 64x64px) with padding. Buttons MUST NOT overlap.

#### Scenario: Touch movement
- GIVEN the player touches the left button
- WHEN the finger is on the button
- THEN move_left action is active
- WHEN the finger lifts
- THEN move_left action is released

#### Scenario: Multi-touch
- GIVEN the player is touching the move-right button
- WHEN the player also touches the jump button
- THEN both inputs are read simultaneously
- AND the player moves right while jumping

### Requirement: Input Map Compatibility

The system MUST use Godot's Input Map actions: `move_left`, `move_right`, `jump`, `attack_light`, `attack_heavy`, `dash`. Both touch and keyboard MUST drive the same actions.

#### Scenario: Dual input
- GIVEN the player is on desktop
- WHEN the player presses keyboard arrow keys
- THEN the player moves via the same Input actions as touch
- AND no code branching for input type is needed

### Requirement: Button Visibility

Buttons SHOULD be semi-transparent (alpha ~0.5) and positioned at screen edges. Movement buttons on the left side. Action buttons (jump, attack, dash) on the right side. Layout MUST adjust to screen size.

#### Scenario: Layout positioning
- GIVEN the game is running on Android
- THEN move buttons are on the bottom-left
- AND jump is on the bottom-right (large, easy to reach)
- AND attack buttons are above jump
- AND dash is next to attacks
