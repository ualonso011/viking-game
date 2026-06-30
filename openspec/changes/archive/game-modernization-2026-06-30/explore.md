# Exploration: game-modernization

## Status: blocked

3 BLOCKER bugs make the game non-functional on any platform. Must be fixed before any UX/visual work.

## Executive Summary

The game has three showstopper bugs that make it completely non-functional: (1) autoload name mismatch — every script references `GameManager`, `GameState`, and `NarrativeDB` in PascalCase but they are registered as `game_manager`, `game_state`, and `narrative_db` in `project.godot`, so ALL method calls silently fail; (2) all `TouchScreenButton` shapes are `null` so touch input never registers on Android; (3) level end-triggers call `main.load_level()` which was removed during the GameManager refactor — the player cannot progress past any level. Additionally, no sprite assets have been generated (all textures/sprite_frames are null), no stretch mode is configured for Android screen scaling, and all Input Map screen-touch bindings share `index=0` causing input overlap. Fixing these blockers should be the absolute first priority before any visual or UX modernization work.

## Key Findings

### Finding 1 — BLOCKER: Autoload name mismatch (root cause of menu button not working)

- **Area**: `autoload/`, all `.gd` scripts
- **Severity**: blocker
- **Evidence**:
  - `project.godot` registers autoloads as: `game_manager`, `game_state`, `audio_manager`, `narrative_db`, `cutscene`
  - `main_menu.gd:72`: calls `GameManager.start_game()` — `GameManager` is not a global name
  - `game_manager.gd:28,51`: calls `GameState.reset_for_level()` — `GameState` is not a global name
  - `player.gd`, `hud.gd`, all `level_*.gd` scripts (~83 occurrences): reference `GameState.*` — `GameState` is not a global name
  - `level_01-07.gd` (5 occurrences): reference `NarrativeDB.*` — `NarrativeDB` is not a global name
  - No script has `class_name GameManager`, `class_name GameState`, or `class_name NarrativeDB` (grep confirms zero `class_name` declarations)
  - Result: `_on_start_pressed()` → `GameManager.start_game()` → undefined identifier → script crashes silently → button does nothing
- **Recommendation**: Either (A) rename all code references to match autoload snake_case names (`game_manager`, `game_state`, `narrative_db`), or (B) add `class_name` declarations to each autoload script. Option A is safer (doesn't risk Godot 4.3 Android export class resolution issues with `class_name`).

### Finding 2 — BLOCKER: Level end triggers call removed method

- **Area**: `scenes/levels/level_01-07.gd`, `scenes/main/main.gd`
- **Severity**: blocker
- **Evidence**:
  - All 7 level scripts call `main.load_level("res://scenes/levels/level_XX.tscn")` on end-trigger enter
  - `main.gd` was refactored to a 16-line container — the `load_level()` method was moved to `game_manager.gd` but the level scripts were never updated
  - `level_07.gd:71` also references `main.current_state = 0` which no longer exists (moved to `game_manager.current_state`)
  - Result: reaching any level exit does nothing — soft lock at the end of every level
- **Recommendation**: Update all level end-trigger handlers to call `game_manager.load_level()` and `game_manager.current_state = game_manager.GameState.MENU` for the final ending.

### Finding 3 — BLOCKER: TouchScreenButton shapes are null

- **Area**: `scenes/ui/touch_controls.tscn`
- **Severity**: blocker
- **Evidence**:
  - All 7 `TouchScreenButton` nodes (JumpBtn, AttackLightBtn, AttackHeavyBtn, DashBtn, FuryBtn, LeftBtn, RightBtn) have `shape = null` in the `.tscn` file
  - `touch_controls.gd` assigns `.action` properties in `_ready()` but never assigns `.shape`
  - Godot docs: "If shape is null, the button will not detect any touches"
  - Result: touch controls are invisible AND non-functional on mobile
- **Recommendation**: Create `CircleShape2D` or `RectangleShape2D` resources for each button and assign them in `_ready()` or in the `.tscn`.

### Finding 4 — CRITICAL: No sprite assets generated

- **Area**: `assets/sprites/`, all `.tscn` files
- **Severity**: critical
- **Evidence**:
  - `assets/sprites/` contains only `generate_placeholders.gd` — zero `.png` files
  - `player.tscn`: `AnimatedSprite2D.sprite_frames = null`, `Sprite2D.texture = null`
  - `soldier.tscn`, `boss.tscn`: `AnimatedSprite2D.sprite_frames = null`
  - `virtual_joystick.tscn`: `Base.texture = null`, `Knob.texture = null`
  - Result: all characters, enemies, joystick are invisible
- **Recommendation**: Run the placeholder generator script to produce the PNG assets. Then create proper `SpriteFrames` resources for the `AnimatedSprite2D` nodes with state-to-frame mappings.

### Finding 5 — CRITICAL: No stretch mode for Android scaling

- **Area**: `project.godot`
- **Severity**: critical
- **Evidence**:
  - `project.godot` sets `window/size/viewport_width=1920` and `window/size/viewport_height=1080`
  - No `window/stretch/mode`, `window/stretch/aspect`, or `window/stretch/scale` settings exist
  - On Android, the game renders at native 1920x1080 regardless of device resolution — on small phones it will be unplayably tiny, on tablets it may be cropped
- **Recommendation**: Stretch mode is needed for proper Android screen scaling BUT **memory #55 documents that Godot 4.3 headless export FAILS when `window/stretch/mode` and `window/stretch/aspect` are present in `project.godot`**. Workaround: apply stretch settings programmatically in an autoload `_ready()` using `get_window().content_scale_mode` and `get_window().content_scale_aspect` instead of putting them in `project.godot`. This keeps the Docker export working while providing proper Android scaling at runtime.
- **⚠ CONFLICT**: This directly conflicts with prior finding that stretch mode settings in `project.godot` break the Docker CI pipeline. The runtime workaround documented above MUST be tested in Docker CI before merging.

### Finding 6 — WARNING: Input map touch index collision

- **Area**: `project.godot` Input Map
- **Severity**: warning
- **Evidence**:
  - `jump`, `attack_light`, `attack_heavy`, `dash`, `fury` ALL use `InputEventScreenTouch` with `index=0`
  - `move_left` and `move_right` use `InputEventScreenDrag` with `index=0`
  - Result: when TouchScreenButton shapes are fixed, pressing one button will still fire ALL actions with the same touch index simultaneously
- **Recommendation**: Either (A) assign unique touch indices per action (simple but fragile), or (B) remove `InputEventScreenTouch` from the Input Map entirely and rely solely on `TouchScreenButton.action` which maps touch region to action by position, not index. Option B is the Godot 4 convention.

### Finding 7 — WARNING: GameManager missing edge cases

- **Area**: `autoload/game_manager.gd`
- **Severity**: warning
- **Evidence**:
  - No `resume_game()` semantic wrapper — pause toggles directly exposed to `_unhandled_input`
  - `load_level()` frees `current_level` before attempting to load — if `load()` fails, the old level is gone but no new level is present (null deref risk)
  - Cutscene manager (`cutscene_manager.gd`) independently calls `get_tree().paused = true/false` — can conflict with GameManager's pause state (e.g., player pauses during cutscene → unpause → cutscene manager thinks game is unpaused but GameManager thinks it's PAUSED)
  - `_set_visible` helper silently no-ops if node not found — no error feedback
  - No cutscene integration: `current_state` has `CUTSCENE` enum value but never transitions to/from it
- **Recommendation**: Add `pause_game()` / `resume_game()` methods that coordinate with cutscene state. Add a guard in `load_level()` to restore or error if loading fails. Wire cutscene begin/end to GameManager state transitions.

### Finding 8 — WARNING: VirtualJoystick scene is orphaned

- **Area**: `scenes/ui/virtual_joystick.tscn`, `scenes/ui/virtual_joystick.gd`
- **Severity**: warning
- **Evidence**:
  - `virtual_joystick.gd` is a full implementation (82 lines) with proper touch detection, deadzone, Input Action emission
  - `touch_controls.tscn` uses discrete `TouchScreenButton` nodes (`LeftBtn`, `RightBtn`) for movement — the `VirtualJoystick` scene is never instantiated anywhere
  - The spec calls for an analog joystick; the current implementation uses binary left/right buttons which is a UX downgrade
- **Recommendation**: Either integrate the VirtualJoystick into `touch_controls.tscn` (replacing LeftBtn/RightBtn) or remove the orphaned files to prevent confusion.

### Finding 9 — WARNING: _set_fury_unlocked is dead code

- **Area**: `autoload/game_state.gd`
- **Severity**: warning
- **Evidence**:
  - `game_state.gd:48-51`: defines `func _set_fury_unlocked(value)` but the `var fury_unlocked` is declared as a plain variable without `set = _set_fury_unlocked`
  - All code directly sets `fury_unlocked = true` and manually emits `fury_unlocked_changed.emit()` afterward
  - The setter function is never called — it's dead code
- **Recommendation**: Either wire the setter properly (`var fury_unlocked: bool = false: set = _set_fury_unlocked`) or remove `_set_fury_unlocked` and keep the explicit signal emit pattern. Wiring the setter is cleaner.

### Finding 10 — SUGGESTION: UI/UX weaknesses

- **Area**: All UI scenes
- **Severity**: suggestion
- **Evidence**:
  - **Typography**: No custom font loaded — all labels use Godot's default bitmap font. The spec calls for a Viking-themed aesthetic but currently uses a sterile system font
  - **Color palette**: Dark background `Color(0.05, 0.05, 0.08)` with amber/gold text `Color(0.7, 0.5, 0.3)` — directionally correct for a "ash and ember" theme but very low contrast and no variation. Enemies, HUD, platforms all use flat ColorRects
  - **Layout**: Main menu uses `VBoxContainer` with manual anchors — functional but not polished. No animations, no background art, no logo
  - **Transitions**: Only fade_in/fade_out on the main scene AnimationPlayer. No transition between menu → gameplay, no checkpoint sparkle, no damage flash beyond alpha flicker
  - **HUD**: Health bar is a `TextureProgressBar` with solid colors — no theme, no border, no texture. Fury icon has no texture (just "F" text)
- **Recommendation**: Load a Viking-themed `.ttf` font (e.g., Norse bold). Add a theme resource for consistent styling. Add tween animations for menu → game transition. Polish the color palette with proper contrast ratios.

### Finding 11 — SUGGESTION: Narrative completeness

- **Area**: `autoload/narrative_db.gd`
- **Severity**: suggestion
- **Evidence**:
  - 6 scenes defined across 4 functions: `intro_farm()` (7 lines), `exile_forest()` (5 lines), `before_halvard()` (8 lines), `final_boss_intro()` (8 lines), `final_boss_defeat()` (11 lines)
  - Missing narrative arcs: Einar's transformation from farmer to warrior (the "ash bear" awakening), the journey through the ruined village, the warpath through the mountains, the England invasion
  - Level 03 (Cinders), Level 04 (Warpath), Level 06 (England Invasion) have no cutscene triggers or narrative content — they're purely gameplay levels
  - Cutscene spec mentions camera movement during scenes — not implemented (no `cutscene_manager.gd` camera control code)
  - The story overall is present as seeds but missing the middle arc that makes "father kills son" a tragedy rather than a random twist
- **Recommendation**: Add 3-5 line cutscenes for levels 03, 04, 06 to build emotional arc. Add camera pan capability to cutscene manager. The narrative_db content is well-written — it just needs to cover the middle chapters.

### Finding 12 — SUGGESTION: Renderer choice

- **Area**: `project.godot` [rendering]
- **Severity**: suggestion
- **Evidence**:
  - `renderer/rendering_method="gl_compatibility"` — lowest-tier renderer, no 2D batching, limited shader support
  - For a 2D sprite game on Android, `mobile` renderer with Vulkan fallback would give better performance and visual effects
  - `gl_compatibility` is the safest choice for very old devices (Android < 8) but `mobile` covers 95%+ of active Android devices
- **Recommendation**: Test with `mobile` renderer. If it works on target devices, switch for better performance. Keep `gl_compatibility` as a fallback export preset.

### Finding 13 — NOTE: What actually works

- **Area**: Core game logic
- **Severity**: note
- **Evidence**:
  - `player.gd`: State machine logic is correct — movement, jump, attacks, dash, hurt, dead states all properly implemented with cooldowns and physics
  - `soldier.gd` / `boss.gd`: AI logic is sound — detection, chase, attack patterns, phase transitions, screen culling
  - `game_state.gd`: Data model and methods are correct — HP, damage, fury, checkpoint management
  - `cutscene_manager.gd`: Core loop works — text display, input blocking, advance/end (with PROCESS_MODE_WHEN_PAUSED)
  - `level_*.gd`: Trigger logic is correct — checkpoint save/restore, cutscene triggers, end triggers (except the `main.load_level()` bug)
  - The game logic is solid — it's only integration issues preventing it from working
- **Recommendation**: Fix the integration bugs (autoload names, level transitions, touch shapes) and the game should be playable.

## Affected Areas

| Path | Status | Issue |
|------|--------|-------|
| `scenes/ui/main_menu.gd` | BROKEN | `GameManager.start_game()` — undefined global |
| `autoload/game_manager.gd` | BROKEN | `GameState.reset_for_level()` x2 — undefined global |
| `scenes/ui/hud.gd` | BROKEN | `GameState.*` references x8 — undefined global |
| `scenes/player/player.gd` | BROKEN | `GameState.*` references x17 — undefined global |
| `scenes/levels/level_01-07.gd` | BROKEN | `GameState.*` references x40+, `NarrativeDB.*` x5, `main.load_level()` x7 — undefined globals + missing method |
| `scenes/ui/touch_controls.tscn` | BROKEN | All `TouchScreenButton.shape = null` — no touch detection |
| `project.godot` | MISSING | No stretch mode, touch index collision in Input Map |
| `assets/sprites/` | MISSING | No generated PNGs — all sprite textures null |
| `scenes/ui/virtual_joystick.*` | ORPHAN | Never instantiated — unused code |
| `autoload/game_state.gd` | BUG | `_set_fury_unlocked` never wired as setter |
| `scenes/cutscene/cutscene_manager.gd` | INCOMPLETE | No camera control implemented |

## Approaches

### Approach A: Fix-only (minimum viable fix)
Fix the 3 blockers only (autoload names, level transitions, touch shapes) + generate sprites + add stretch mode. Game becomes playable. ~2 hours of work. Defer all UX/visual modernization to a follow-up change.

- **Pros**: Fast, low risk, gets the game working immediately
- **Cons**: Game will be ugly with placeholder graphics, no polish, poor UX on Android
- **Effort**: Low

### Approach B: Fix + Polish (recommended)
Fix all blockers AND warnings simultaneously, add font, generate sprites, add transitions, fix HUD layout, implement stretch mode. Package as a single modernization change. ~6-8 hours of work across all phases.

- **Pros**: Single delivery that makes the game both functional AND presentable
- **Cons**: Larger scope, more testing needed, may benefit from splitting into sub-tasks
- **Effort**: Medium

### Approach C: Phase-split
Fix blockers (Phase 1) → test on device → then modernize UI/visuals (Phase 2) → then narrative expansion (Phase 3). Each phase independently shippable.

- **Pros**: Iterative delivery, each phase testable, risk contained per phase
- **Cons**: 3x spec/design overhead, user waits longer for polished experience
- **Effort**: Medium-High (due to overhead)

## Recommendation

**Approach B — Fix + Polish in a single coordinated change.**

Rationale: The blocker fixes are mechanical (rename globals, assign shapes, update method calls) and the visual modernization is mostly asset generation + styling. These are not architecturally risky changes — they're integration fixes and content work. Splitting them would add unnecessary SDD ceremony for what is essentially a "make it work + make it pretty" pass. The user has been fighting this for several rounds and wants a working, polished game, not just a bugfix.

The specific fix for the autoload name mismatch: rename ALL PascalCase references (`GameManager` → `game_manager`, `GameState` → `game_state`, `NarrativeDB` → `narrative_db`) rather than adding `class_name`. This avoids Godot 4.3 Android export issues with global class resolution and is a simple search-and-replace operation across ~10 files.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Autoload rename introduces new typos | Medium | High | Use grep to verify zero remaining `GameManager`/`GameState`/`NarrativeDB` references after fix |
| Touch shape sizes don't match layout on small screens | Medium | Medium | Set shapes relative to control size; test with Godot editor's "Emulate Touch from Mouse" |
| Sprite generation script fails headless | Low | Medium | Run in Godot editor once to generate, commit the resulting PNGs |
| Stretch mode breaks camera or UI layout | Medium | High | Test with multiple window sizes in editor before exporting; `canvas_items` mode preserves pixel alignment |
| Stretch mode settings in project.godot break headless Docker export | High | High | **CONFIRMED by prior memory #55**: apply stretch via `get_window()` at runtime in an autoload, NOT in project.godot |
| gdscript type hints cause Android parse errors | Medium | Medium | Godot 4.3 Android export is picky about script parsing — ensure all `@onready` and typed arrays are syntactically valid |

## Open Questions

1. **Custom font**: Do you have a specific Viking-themed font file (.ttf/.otf) in mind, or should I use a bundled free font (e.g., Norse Bold, Cinzel, Uncial Antiqua)?
2. **Color palette**: Do you want to keep the dark "ash and ember" theme (dark blues + amber/gold) or pivot to a different aesthetic?
3. **Virtual joystick**: Should I integrate the orphaned `VirtualJoystick` (analog) or keep the discrete left/right buttons? The joystick gives smoother movement but requires more touch area.
4. **Android export**: Do you want me to test the Docker export pipeline as part of this change, or is that for a separate phase?
5. **Narrative expansion**: Would you like me to write new dialogue lines for the 3 missing levels (Cinders, Warpath, England), or do you want to write them yourself?
6. **Renderer**: Switch to `mobile` renderer or stay with `gl_compatibility`? Tradeoff: better performance vs. broader device compatibility.
7. **IMPORTANT — Stretch mode conflict**: Memory #55 documents that adding `window/stretch/mode` to `project.godot` breaks the headless Docker export. The proposed workaround (runtime `get_window()` calls) should be tested in CI before committing. Do you agree with this approach?

## Next Recommended

Proceed to `sdd-propose` with Approach B (fix + polish). The proposal should scope the 3 blocker fixes as non-negotiable, the autoload rename strategy (snake_case code references), and group the UX/visual work into a single change. Address the open questions before writing the spec.
