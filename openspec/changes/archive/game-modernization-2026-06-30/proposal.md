# Proposal: Game Modernization — Fix Blockers + Visual Polish

## Intent

Three blocker bugs make the game completely non-functional: (1) autoload name casing mismatch — ~83 references use `GameManager`/`GameState`/`NarrativeDB` but `project.godot` registers them as `game_manager`/`game_state`/`narrative_db`, so all method calls silently fail; (2) all 7 `TouchScreenButton` shapes are `null` — touch input never registers on Android; (3) level end-triggers call `main.load_level()` which was removed during the GameManager refactor — the player cannot progress past any level. Combined with missing sprites, no stretch mode, and input map collisions, the game is unplayable end-to-end. This change fixes all blockers and applies visual modernization (font, theme, transitions, sprite generation) while preserving the Viking "ash and ember" story theme.

## Scope

### In Scope
- Fix autoload name casing: rename all PascalCase references → snake_case (`game_manager`, `game_state`, `narrative_db`) across ~10 scripts
- Fix level end-triggers: update `main.load_level()` → `game_manager.load_level()` in all 7 level scripts
- Fix TouchScreenButton shapes: assign `CircleShape2D` resources with concrete sizes (movement buttons: radius 80px; action buttons: radius 60px — sized for 1080p Android tap targets)
- Apply stretch mode at runtime via `get_window().content_scale_mode` (NOT in `project.godot` — per memory #55, project.godot stretch settings break Docker CI export)
- Generate placeholder sprite PNGs via `generate_placeholders.gd`
- Fix Input Map touch index collision (remove `InputEventScreenTouch` from Input Map, rely on `TouchScreenButton.action`)
- Wire `_set_fury_unlocked` setter properly in `game_state.gd`
- Visual polish: Viking-themed `.ttf` font, `Theme` resource, menu→game tween transitions, HUD styling

### Out of Scope
- Sound effects / music
- New levels or gameplay mechanics
- iOS export
- Narrative content expansion (levels 03, 04, 06 cutscenes)
- Renderer switch (`gl_compatibility` → `mobile`)
- VirtualJoystick integration (deferred — discrete buttons work after shape fix)

## Capabilities

### New Capabilities
- `ui-modernization`: Theme resource, Viking font, transition animations, HUD visual polish

### Modified Capabilities
- `touch-controls`: Assign `CircleShape2D` to all 7 buttons; fix Input Map touch collision
- `level-system`: Update end-trigger handlers from `main.load_level()` → `game_manager.load_level()`
- `hud-system`: Apply theme styling to health bar and fury indicator

## Approach Comparison

| Approach | Effort | Pros | Cons |
|----------|--------|------|------|
| A: Fix-only | ~2h | Fast, low risk | Game works but looks broken; poor UX |
| **B: Fix + Polish (recommended)** | **~6-8h** | **Single delivery, functional + presentable** | **Larger review scope (~120 est. lines, within 400-line budget)** |
| C: 3-phase | ~8-10h + 3x overhead | Iterative | Excessive SDD ceremony for mechanical fixes; user waits longer |

**Selected: Approach B.** Fixes are mechanical (rename + rewire); polish is asset + styling. Splitting adds ceremony without reducing risk. Tasks grouped into review phases: Phase 1 (blockers), Phase 2 (stretch + sprites + input), Phase 3 (visual polish).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `scenes/main/main_menu.gd` | Modified | `GameManager` → `game_manager` |
| `autoload/game_manager.gd` | Modified | `GameState` → `game_state` |
| `scenes/ui/hud.gd` | Modified | `GameState` → `game_state` (~8 refs) |
| `scenes/player/player.gd` | Modified | `GameState` → `game_state` (~17 refs) |
| `scenes/levels/level_01-07.gd` | Modified | `GameState` → `game_state`, `NarrativeDB` → `narrative_db`, `main.load_level()` → `game_manager.load_level()` |
| `scenes/ui/touch_controls.gd` | Modified | Assign `CircleShape2D` per button in `_ready()` |
| `scenes/ui/touch_controls.tscn` | Modified | Button layout adjustments for shape sizes |
| `autoload/stretch_mode.gd` | New | Runtime `get_window().content_scale_mode = CANVAS_ITEMS` |
| `project.godot` | Modified | Register `stretch_mode` autoload (NO stretch settings in project.godot) |
| `assets/sprites/` | Modified | Generated placeholder PNGs |
| `autoload/game_state.gd` | Modified | Wire `fury_unlocked` setter |
| `scenes/ui/main_menu.gd` | Modified | Add tween transition for game start |
| `assets/themes/viking_theme.tres` | New | Global theme with font, colors, styles |

**NOT modified**: `project.godot` stretch settings (runtime only), renderer method.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Autoload rename introduces typos → silent method failures | Medium | grep verification: zero remaining `GameManager`/`GameState`/`NarrativeDB` after fix |
| Touch shape sizes too small/large on real devices | Medium | Movement: radius 80px (160px diameter); Action: radius 60px (120px diameter). Test with "Emulate Touch from Mouse" at 1080x1920 viewport |
| Runtime stretch mode via `get_window()` fails in Docker CI | Medium | Test `get_window().content_scale_mode` in Docker headless before committing; fallback: skip stretch if `get_window()` returns null |
| GDScript type hints cause Android parse errors (prior `AnimationPlayer: AnimationPlayer` bug) | Medium | Avoid redundant type-hint pattern; validate all `@onready` and typed arrays compile on Android export |
| Sprite generation script fails headless | Low | Run in Godot editor once, commit resulting PNGs |

## Open Questions

| # | Question | Priority |
|---|----------|----------|
| 1 | Custom Viking font: provide a `.ttf`/`.otf` or use bundled free font (Cinel, Norse Bold, Uncial Antiqua)? | High |
| 2 | Keep dark "ash and ember" palette (dark blues + amber/gold) or pivot? | Normal |
| 3 | Integrate VirtualJoystick (analog) or keep discrete left/right buttons? | Normal |
| 4 | Test Docker export pipeline in this change or defer? | Normal |
| 5 | Write narrative dialogue for levels 03, 04, 06 or user authors? | Low |
| 6 | Switch to `mobile` renderer or stay `gl_compatibility`? | Low |
| 7 | Runtime stretch via `get_window()` — confirmed acceptable? (memory #55 blocks project.godot approach) | Blocker |

## Assumptions

Made where open questions are deferred:
- Font: will use a free Viking-compatible `.ttf` (Cinel or similar) if no custom font provided
- Palette: keeping dark "ash and ember" theme with improved contrast ratios
- Stretch: `canvas_items` mode applied at runtime; `get_window()` approach is confirmed safe
- VirtualJoystick: deferred to follow-up; discrete buttons fixed first
- Narrative: not expanded in this change
- Renderer: staying on `gl_compatibility`

## Acceptance Criteria

### MUST (blockers — game must be playable)

**AC-1: Menu starts game**
- GIVEN the main menu is displayed
- WHEN the user taps "EMPEZAR"
- THEN `game_manager.start_game()` is called
- AND the game transitions to Level 01

**AC-2: Level progression works**
- GIVEN the player reaches any level-end trigger
- WHEN the player overlaps the end Area2D
- THEN `game_manager.load_level()` loads the next level scene
- AND the transition completes without null dereference

**AC-3: Touch controls respond**
- GIVEN the game is running on Android
- WHEN the user taps any of the 7 buttons (Jump, AttackLight, AttackHeavy, Dash, Fury, Left, Right)
- THEN the corresponding input action fires
- AND no cross-triggering from shared touch index

**AC-4: Autoload references resolve**
- GIVEN any script in the project
- WHEN it calls `game_state.*`, `game_manager.*`, or `narrative_db.*`
- THEN the call resolves without "identifier not found" errors
- AND zero PascalCase autoload references remain (verified by grep)

### SHOULD (polish — game should look presentable)

**AC-5: Android screen scaling**
- GIVEN the game runs on an Android device with non-1920x1080 resolution
- WHEN the game starts
- THEN `canvas_items` stretch mode scales UI and gameplay proportionally
- AND the Docker CI export still succeeds (no project.godot stretch settings)

**AC-6: Visual theme applied**
- GIVEN the game is running
- WHEN any UI element is displayed (menu, HUD, cutscene text)
- THEN the Viking-themed font and color palette are used consistently

**AC-7: Menu transition**
- GIVEN the user taps "EMPEZAR"
- WHEN the game transitions from menu to gameplay
- THEN a fade or tween animation plays (not an instant cut)

### MAY (nice to have)

**AC-8: Fury setter wired**
- GIVEN `fury_unlocked` is set to `true`
- THEN the setter auto-emits `fury_unlocked_changed` signal without manual emit calls

## Dependencies

- Godot 4.3 stable (development + Android export)
- Docker with `robpc/godot-headless:4.3-android` for CI export validation
- Free Viking-themed `.ttf` font (Cinel, Norse Bold, or Uncial Antiqua)
- Memory #55 context: `project.godot` stretch settings break headless export

## Rollback Plan

Git revert the merge commit. All changes are in GDScript files, `.tscn` files, and one new autoload — no database or persistent state changes. Each review phase (blockers / stretch+input / polish) is a separate commit that can be reverted independently. The autoload rename is the highest-risk change; if it causes issues, reverting just that commit restores the previous (broken but known) state.

## Success Criteria

- [ ] Game runs end-to-end on Android: menu → Level 01 → Level 07 → ending
- [ ] All 7 touch buttons respond correctly without cross-triggering
- [ ] Zero `GameManager`/`GameState`/`NarrativeDB` PascalCase references in codebase
- [ ] Stretch mode scales properly at 1080x1920 and 1080x2340 viewports
- [ ] Docker CI export produces a valid APK without errors
- [ ] Viking-themed font applied to all UI elements
- [ ] Menu → game transition uses tween animation (not instant cut)
- [ ] No `AnimationPlayer: AnimationPlayer` type-hint pattern in any script
