# Level Load Calls Specification

## Purpose

Define how level-end triggers advance the player through the game's level sequence via a centralized scene flow manager.

## Requirements

### Requirement: Level-End Trigger Advances via game_manager

All level scripts (`scenes/levels/level_01.gd` through `level_07.gd`) MUST call `game_manager.load_level(next_path)` when the player overlaps the EndTrigger Area2D. References to `main.load_level()` MUST be removed. The `next_path` argument SHALL be the `res://` path to the subsequent level scene.

For Level 07 (final level), the end trigger MUST call `game_manager` to transition to the ending sequence instead of loading a non-existent Level 08.

#### Scenario: Level 1 advances to Level 2

- GIVEN the player is in Level 01
- WHEN the player overlaps the EndTrigger Area2D
- THEN `game_manager.load_level("res://scenes/levels/level_02.tscn")` is called
- AND Level 02 loads without null dereference

#### Scenario: Level 2 advances to Level 3

- GIVEN the player is in Level 02
- WHEN the player overlaps the EndTrigger Area2D
- THEN `game_manager.load_level("res://scenes/levels/level_03.tscn")` is called
- AND Level 03 loads successfully

#### Scenario: Level 7 triggers ending

- GIVEN the player is in Level 07
- WHEN the player overlaps the EndTrigger Area2D
- THEN the ending sequence is triggered via `game_manager`
- AND no attempt to load a non-existent Level 08 occurs
