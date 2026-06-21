# Level System Specification

## Purpose

Define the 7 linear side-scrolling levels built with TileMapLayer. Each level is left→right progression with checkpoints, enemies, and cutscene triggers.

## Requirements

### Requirement: Level Structure

Each level MUST be a Node2D root with TileMapLayer children, Player spawn, Enemy spawns, Checkpoints, Cutscene triggers, and Level-end trigger. Levels MUST load independently via `change_scene_to_file()`.

#### Scenario: Level transition
- GIVEN the player reaches the level-end trigger
- THEN a fade-to-black effect plays
- AND GameState.current_level increments
- AND the next level scene loads

### Requirement: Checkpoints

Checkpoints MUST be Area2D triggers. When the player overlaps, the checkpoint position is saved in GameState. On death, the player respawns at the last checkpoint. Visual feedback: banner or icon appears.

#### Scenario: Activate checkpoint
- GIVEN the player walks into a checkpoint Area2D
- THEN the checkpoint position is saved
- AND visual feedback is shown
- AND the player's HP is restored to full

#### Scenario: Respawn at checkpoint
- GIVEN the player dies
- THEN the player respawns at the last activated checkpoint
- AND all enemies respawn
- AND the player has full HP

### Requirement: Level Layout

Levels MUST scroll from left to right. Minimum level width: ~3000px (~20 screen widths at 160px tile size). Terrain, platforms, and decorative layers use separate TileMapLayer nodes. No scrolling back (optional one-way gates).

#### Scenario: Level progression
- GIVEN the player starts at the left spawn point
- WHEN the player moves right
- THEN new terrain and enemies appear
- AND the camera follows the player

### Requirement: Level List

| Level | Theme | Enemies | Boss |
|-------|-------|---------|------|
| Level_01_Farm | Green pastures, farmhouse | 2 Soldiers | None |
| Level_02_Exile | Burned forest, ash | 4 Soldiers | Mini-boss |
| Level_03_Cinders | Ruined village, fire | 5 Soldiers | None |
| Level_04_Warpath | Snowy mountains, fort | 6 Soldiers | None |
| Level_05_HalvardBoss | Jarl's hall | None | Jarl Halvard |
| Level_06_EnglandInvasion | English castle siege | 8 Soldiers | None |
| Level_07_FinalBoss | Ash-covered battlefield | None | Final Boss (son) |
