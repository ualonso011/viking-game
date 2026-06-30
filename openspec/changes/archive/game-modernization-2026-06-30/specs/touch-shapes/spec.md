# Delta for Touch Screen Button Shapes

## ADDED Requirements

### Requirement: Non-Null Touch Shapes

All `TouchScreenButton` nodes MUST have a non-null `shape` resource assigned (`CircleShape2D` or `RectangleShape2D`). Buttons with null shapes SHALL NOT be deployed — Godot ignores touches on shapeless buttons.

### Requirement: Button Shape Sizes

Right-side action buttons (Jump, AttackLight, AttackHeavy, Dash, Fury) MUST use `CircleShape2D` with radius 80px (160px diameter). Centers MUST be separated by at least 100px to prevent accidental multi-triggers.

Left-side movement buttons (Left, Right) MUST use `CircleShape2D` with radius 60px (120px diameter). Centers MUST be separated by at least 100px.

#### Scenario: Tapping right-side action button triggers correct action

- GIVEN the game is running on Android with touch controls visible
- WHEN the user taps the Jump button area (radius 80px from center)
- THEN the `jump` input action fires
- AND no other action (attack_light, attack_heavy, dash) fires from the same tap

#### Scenario: Tapping left-side movement button triggers correct action

- GIVEN the game is running on Android
- WHEN the user taps the Left button area (radius 60px from center)
- THEN the `move_left` input action fires
- AND `move_right` does NOT fire

#### Scenario: Simultaneous movement and jump

- GIVEN the user is holding the Right button
- WHEN the user also taps the Jump button with a second finger
- THEN both `move_right` and `jump` actions fire simultaneously
- AND no cross-triggering occurs from shared touch index
