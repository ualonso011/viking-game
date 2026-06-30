# Delta for Autoload Names

## ADDED Requirements

### Requirement: Autoload Reference Casing

All scripts MUST reference autoloads using the exact snake_case names registered in `project.godot`: `game_state`, `game_manager`, `audio_manager`, `narrative_db`, `cutscene`. All PascalCase references (e.g. `GameManager`, `GameState`, `NarrativeDB`) MUST be replaced with their snake_case equivalents. Zero PascalCase autoload references SHALL remain after the fix (verified by grep).

Affected files: `scenes/ui/main_menu.gd`, `autoload/game_manager.gd`, `scenes/ui/hud.gd`, `scenes/player/player.gd`, `scenes/levels/level_01-07.gd`.

#### Scenario: Menu button starts the game

- GIVEN the main menu scene is displayed
- WHEN the user taps "EMPEZAR"
- THEN `game_manager.start_game()` is called successfully (no "identifier not found" error)
- AND the game transitions to Level 01

#### Scenario: HUD updates with player HP

- GIVEN the player is in gameplay
- WHEN the player takes damage
- THEN `game_state.current_hp` is read by `hud.gd` without error
- AND the health bar reflects the updated HP value

#### Scenario: Zero PascalCase references remain

- GIVEN the fix is applied
- WHEN a grep searches for `GameManager|GameState|NarrativeDB|AudioManager|CutsceneManager` across all `.gd` files
- THEN zero matches are found
