# Delta for Stretch Mode (Runtime)

## ADDED Requirements

### Requirement: Runtime Stretch Configuration

The `game_manager.gd` autoload `_ready()` MUST configure the window for Android display using `get_window()` API calls. The stretch mode `canvas_items` with aspect `keep` MUST be applied at runtime, NOT in `project.godot` (stretch settings in `project.godot` break Docker CI headless export per memory #55).

### Requirement: Window Configuration

The runtime setup SHALL set: `get_window().content_scale_mode = WINDOW_CONTENT_SCALE_MODE_CANVAS_ITEMS`, `get_window().content_scale_aspect = WINDOW_CONTENT_SCALE_ASPECT_KEEP`, and an appropriate `content_scale_size` targeting 1920x1080. The renderer MUST remain `gl_compatibility`.

### Requirement: Null-Safe Window Access

The stretch configuration MUST guard against `get_window()` returning null (headless/CI environments). If null, stretch configuration SHALL be skipped silently without crashing.

#### Scenario: Android device scales correctly

- GIVEN the game runs on an Android device with 1080x2340 resolution
- WHEN the game starts
- THEN `canvas_items` stretch mode scales UI and gameplay proportionally to fit the screen
- AND the 1920x1080 design viewport is maintained with `keep` aspect

#### Scenario: Docker CI export succeeds

- GIVEN the Docker headless export runs
- WHEN the game is exported to APK
- THEN no stretch-related errors occur (stretch is NOT in `project.godot`)
- AND the export completes successfully

#### Scenario: Headless null-window guard

- GIVEN the game runs in a headless environment where `get_window()` returns null
- WHEN `_ready()` executes the stretch configuration
- THEN the null check prevents a crash
- AND the game continues without stretch (graceful degradation)
