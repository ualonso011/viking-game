# Player System Specification

## Purpose

Define the player character (Einar) — a CharacterBody2D with 6 animation states, 5 mechanics, health, and combat capabilities.

## Requirements

### Requirement: Movement

The player MUST move left/right on input. Movement speed SHOULD be ~200 px/s. Acceleration and friction SHOULD be applied for smooth feel.

#### Scenario: Move right
- GIVEN the player is on the ground
- WHEN the player presses right
- THEN the player moves right at configured speed
- AND the sprite faces right

#### Scenario: Move left
- GIVEN the player is on the ground
- WHEN the player presses left
- THEN the player moves left at configured speed
- AND the sprite faces left

### Requirement: Jump

The player MUST jump when the jump button is pressed while on the floor. Jump velocity SHOULD be ~-400 px/s (negative Y). Variable jump height SHOULD be supported (release early = lower jump).

#### Scenario: Basic jump
- GIVEN the player is on the ground
- WHEN the player presses jump
- THEN the player gains upward velocity

#### Scenario: Variable jump height
- GIVEN the player is ascending from a jump
- WHEN the player releases the jump button early
- THEN the upward velocity cuts by 50%

### Requirement: Light Attack

The player MUST perform a fast melee attack on light attack input. Damage: 1 HP. Cooldown: ~0.3s. Hitbox active for ~0.15s. Movement halved during attack.

#### Scenario: Light attack hits enemy
- GIVEN the player is near an enemy
- WHEN the player presses light attack
- THEN the attack hitbox activates for 0.15s
- AND enemies in range take 1 damage

### Requirement: Heavy Attack

The player MUST perform a slow powerful attack on heavy attack input. Damage: 2 HP. Cooldown: ~0.8s. Hitbox active for ~0.3s. Movement locked during attack.

#### Scenario: Heavy attack hits enemy
- GIVEN the player is near an enemy
- WHEN the player presses heavy attack
- THEN the heavy attack hitbox activates for 0.3s
- AND enemies in range take 2 damage
- AND enemies receive knockback

### Requirement: Dash

The player MUST dash forward on dash input. Dash distance: ~150px. Duration: ~0.3s. Invulnerable during dash. Cooldown: ~1s.

#### Scenario: Dash while moving right
- GIVEN the player is on the ground
- WHEN the player presses dash while holding right
- THEN the player dashes right at high speed
- AND takes no damage during the dash

### Requirement: States

The player MUST have these states: idle, run, jump, attack, hurt, dead. Animation MUST match current state.

#### Scenario: State transitions
- GIVEN the player is idle
- WHEN horizontal input is detected
- THEN state changes to run
- WHEN jump is pressed on ground
- THEN state changes to jump
- WHEN attack input is pressed
- THEN state changes to attack
- WHEN damage is taken and HP > 0
- THEN state changes to hurt

### Requirement: Damage and Death

The player MUST take damage when hit, with brief invulnerability (1s). At 0 HP, enter dead state, trigger death sequence, respawn at last checkpoint.

#### Scenario: Take damage
- GIVEN the player has 3 HP
- WHEN the player is hit by an enemy
- THEN HP decreases by 1
- AND the player enters hurt state for 0.5s
- AND the player is invulnerable for 1s

#### Scenario: Death
- GIVEN the player has 1 HP
- WHEN the player is hit
- THEN HP becomes 0
- AND the player enters dead state
- AND the death animation plays
- AND the player respawns at last checkpoint after 2s
