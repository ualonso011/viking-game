# Sprite Assets Specification

## Purpose

Define the placeholder sprite generation and asset swap strategy for all entity visual representations.

## Requirements

### Requirement: Non-Null Sprite Textures

All `AnimatedSprite2D` and `Sprite2D` nodes that currently have null textures MUST have valid texture resources assigned. Nodes affected: player (`player.tscn`), soldiers (`soldier.tscn`), boss (`boss.tscn`), and UI elements (`virtual_joystick.tscn`).

### Requirement: Placeholder Asset Strategy

Until final sprite PNGs are produced, the system SHALL use Godot built-in primitives as visual stand-ins: `ColorRect` nodes or `GradientTexture2D` resources with distinct colors per entity type (player: amber, soldier: gray, boss: dark red). Placeholder textures MUST be clearly distinguishable from each other.

### Requirement: Placeholder-to-Final Asset Path

A `generate_placeholders.gd` script SHALL produce placeholder PNGs in `assets/sprites/`. When final art assets replace placeholders, the scene files MUST reference the new PNG paths without requiring code changes. Texture assignments SHOULD use exported variables or resource references that can be swapped in the editor.

#### Scenario: Player sprite is visible at runtime

- GIVEN the game loads Level 01
- WHEN the player character spawns
- THEN the player's `AnimatedSprite2D` displays a visible placeholder texture (not null/invisible)

#### Scenario: Enemy sprites are visible

- GIVEN the game loads a level with soldiers
- WHEN the level initializes
- THEN each soldier's `AnimatedSprite2D` displays a visible placeholder texture

#### Scenario: Final asset swap without code changes

- GIVEN placeholder PNGs are in `assets/sprites/`
- WHEN a designer replaces `player_idle.png` with final art
- THEN the scene displays the new art without any `.gd` script modifications
