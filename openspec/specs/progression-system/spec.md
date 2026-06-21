# Progression System Specification

## Purpose

Define player stat progression across levels and the "Furia del Oso" (Bear's Fury) special ability.

## Requirements

### Requirement: Furia del Oso

The player MUST gain the "Furia del Oso" ability after Level_01. When activated: damage increased by 50% for 5s, invulnerable during activation, cooldown of 30s. Visual: red glow around the player.

#### Scenario: Activate Furia del Oso
- GIVEN the player has completed Level_01
- AND the ability is not on cooldown
- WHEN the player presses the fury button
- THEN Furia del Oso activates for 5s
- AND damage output increases by 50%
- AND the player glows red
- AND the cooldown timer starts (30s)

#### Scenario: Furia del Oso on cooldown
- GIVEN Furia del Oso was just used
- THEN the ability button is disabled
- AND the cooldown indicator shows remaining time
- AFTER 30s
- THEN the ability is ready again

### Requirement: Stat Scaling

Player damage SHOULD increase per level: base 1 (light) / 2 (heavy). Each completed level adds +0.5 (+1 at levels 3, 5, 7). Max HP SHOULD increase at checkpoints with lore significance.

#### Scenario: Level completion scaling
- GIVEN the player completes Level_01
- THEN base damage increases to 1.5 (light) / 2.5 (heavy)
- AND this applies to all subsequent levels

### Requirement: Checkpoint Healing

Checkpoints MUST restore the player to full HP. Some story checkpoints MAY increase max HP by +1.

#### Scenario: HP upgrade
- GIVEN the player activates a story checkpoint
- THEN max HP increases by 1
- AND current HP is set to the new max
