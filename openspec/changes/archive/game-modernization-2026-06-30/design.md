# Design: Game Modernization — Fix Blockers + Visual Polish

## Technical Approach

**Approach B from the proposal**: fix the three blocker bugs and apply visual polish in a single coordinated change. The strategy is mechanical rename + rewire for blockers (autoload casing, level transitions, touch shapes) plus programmatic asset generation and runtime stretch configuration for polish. No new gameplay mechanics, no renderer switch, no iOS export. Stretch mode is applied via `get_window()` in an autoload `_ready()` (NOT in `project.godot`) to keep Docker CI headless export working — this is the binding constraint from memory #55.

The 7 spec files (autoload-names, level-load-calls, touch-shapes, stretch-mode, sprite-assets, main-menu, hud-modernization) all map 1:1 to the file changes below. The design favors in-place `.gd` rewrites over adding `class_name` declarations to autoloads because `class_name` causes Android export class-resolution issues in Godot 4.3.

---

## Architecture Decisions

### ADR-001: Autoload snake_case accessed as-is in GDScript

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Add `class_name GameManager` to autoloads | Works on desktop, breaks on Android export (class resolution bug 4.3) | **Reject** |
| Rename code references `GameManager` → `game_manager` | Simple, Android-safe, ~91 sed replacements | **Choose** |
| Wrap each autoload in a static `Ref` helper | Indirection, more files, no benefit | **Reject** |

**Rationale**: GDScript autoloads are exposed as globals under the exact name registered in `project.godot`. The PascalCase convention works only with `class_name`. Renaming code is mechanical and grep-verifiable.

### ADR-002: GameManager is the single source of truth for scene flow

| Concern | Current | Target |
|---------|---------|--------|
| Scene transitions | `Main` had `load_level()`, was removed in refactor | `game_manager.load_level()` |
| Pause state | Direct `get_tree().paused = true/false` from input handler | `game_manager.current_state` + `get_tree().paused` (already in `game_manager.gd`) |
| Level end → next level | `main.load_level(...)` (broken — method gone) | `game_manager.load_level("res://...")` |
| Final level ending | `level_07.gd:71` does `main.current_state = 0` then `change_scene_to_file` directly | `game_manager.return_to_menu()` new method, level calls it once |

**Rationale**: Centralizing scene flow in one autoload means all callers have one entry point. The current scattered `main.load_level()`, `main.current_state = 0`, and direct `change_scene_to_file` calls create three different "transitions" with three different failure modes.

### ADR-003: Runtime stretch via `get_window()` (not `project.godot`)

```gdscript
# In game_manager.gd _ready()
var win = get_window()
if win:
    win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
    win.content_scale_size = Vector2i(1920, 1080)
```

**Rationale**: Memory #55 documents that `window/stretch/*` keys in `project.godot` break Godot 4.3 headless Docker export. `get_window()` works at runtime in the player, and the null guard (`if win`) prevents crash in headless CI. The viewport size in `project.godot` (1920x1080) is preserved as the design target.

### ADR-004: No redundant type-hint pattern

**Banned pattern** (prior `AnimationPlayer: AnimationPlayer` Android parse bug):
```gdscript
@onready var ap: AnimationPlayer = $AnimationPlayer  # type redundant, causes Android parse error
```

**Accepted patterns**:
```gdscript
@onready var ap = $AnimationPlayer                    # inferred
@onready var player: Node = $Player                   # explicit when downcast needed
@onready var atk_area: Area2D = $AttackArea           # explicit for Area2D API access
```

**Rationale**: `main.gd:14` currently has `var ap = $AnimationPlayer` (inferred — good). Apply the same convention everywhere new code lands. Avoid `var x: SomeType = $SomeType` unless the type provides API the consumer uses (e.g. `Area2D.body_entered`).

### ADR-005: TouchScreenButton shapes = CircleShape2D with concrete radii

| Element | Shape | Radius | Diameter | Center distance |
|---------|-------|--------|----------|-----------------|
| Right side (Jump, AttackLight, AttackHeavy, Dash, Fury) | `CircleShape2D` | 80px | 160px | ≥100px (per spec) |
| Left side (Left, Right) | `CircleShape2D` | 60px | 120px | ≥100px (per spec) |

**Rationale**: Circles match fingertip geometry better than rectangles. 80px radius / 160px diameter is the iOS HIG / Material Design touch target minimum (~48dp ≈ 160px at 1080p). 60px is acceptable for movement buttons because the player holds them (lower precision required). Shapes are assigned in `touch_controls.gd _ready()` because `.tscn` resource paths to `Shape2D` are fragile across renames.

---

## Node Tree Diagrams

### Current `/root` (broken)

```
/root
├── game_manager     (autoload Node)         ← registered, but unused (GameManager PascalCase fails)
├── game_state       (autoload Node)         ← registered, but unused (GameState PascalCase fails)
├── audio_manager    (autoload Node)         ← working
├── narrative_db     (autoload Node)         ← registered, but unused (NarrativeDB PascalCase fails)
├── cutscene         (autoload scene inst)   ← working
└── Main             (Node — main.tscn)
    ├── FadeRect     (ColorRect, full 1920x1080)
    ├── AnimationPlayer (fade_in / fade_out)
    ├── MainMenu     (CanvasLayer, layer 10)
    │   ├── Background (ColorRect, dark blue)
    │   └── VBoxContainer
    │       ├── TitleLabel     "LAS CENIZAS DEL OSO"
    │       ├── SubtitleLabel  "Un viaje vikingo de ceniza y acero"
    │       └── StartButton    "EMPEZAR"  ── button.pressed ──→ GameManager.start_game()  ❌ UNDEFINED
    ├── HUD          (CanvasLayer)
    │   ├── HealthBar (TextureProgressBar)         ← reads GameState.*  ❌ UNDEFINED
    │   ├── FuryIcon, FuryCooldown, FuryLabel
    │   ├── LevelName, CheckpointBanner
    └── TouchControls (CanvasLayer, layer 2)
        ├── RightControls
        │   ├── JumpBtn (TouchScreenButton shape=null)        ❌ NO TOUCH
        │   ├── AttackLightBtn (shape=null)                  ❌
        │   ├── AttackHeavyBtn (shape=null)                  ❌
        │   ├── DashBtn (shape=null)                         ❌
        │   └── FuryBtn (shape=null)                        ❌
        └── LeftControls
            ├── LeftBtn (shape=null)                         ❌
            └── RightBtn (shape=null)                        ❌
```

### Target `/root` (after change)

```
/root
├── game_manager     (autoload Node, refs renamed)
├── game_state       (autoload Node, setter wired)
├── audio_manager    (autoload Node)
├── narrative_db     (autoload Node, refs renamed)
├── cutscene         (autoload scene inst)
└── Main             (Node — main.tscn, unchanged structure)
    ├── FadeRect, AnimationPlayer
    ├── MainMenu     — title fade-in tween, button glow
    ├── HUD          — vignette gradient overlay, smooth HP lerp
    └── TouchControls — all 7 shapes assigned
        (no InputEventScreenTouch in Input Map; TouchScreenButton.action dispatches by position)
```

### Level scene structure (typical, e.g. level_01.tscn)

```
Level_01 (Node2D — scene root)
├── Player              (CharacterBody2D — player.gd)
│   ├── AnimatedSprite2D (sprite_frames → player_idle.png, attack.png)
│   ├── Sprite2D          (texture → player_idle.png, fallback)
│   ├── AttackArea (Area2D)
│   │   └── CollisionShape2D
│   └── CollisionShape2D
├── Checkpoint (Area2D)         — checkpoint body
├── EndTrigger (Area2D)         — end body  ──→ game_manager.load_level(level_02)
├── IntroTrigger (Area2D)       — story body ──→ cutscene.play_cutscene(narrative_db.intro_farm())
├── (level-specific geometry: TileMaps, Soldier, Boss, etc.)
```

### GameManager autoload structure

```
game_manager (Node, autoload)
├── enum GameState { MENU, PLAYING, CUTSCENE, PAUSED }
├── current_state: GameState    (default MENU)
├── current_level: Node         (current level instance, freed on transition)
├── _ready()                    — apply stretch mode via get_window()
├── _unhandled_input(event)     — ui_cancel toggles PAUSED/PLAYING
├── start_game()                — hides menu, awaits load_level(level_01)
├── load_level(path)            — fade out → free old → instantiate → reset state → fade in
├── return_to_menu()            — NEW: resets GameState, reloads main.tscn
└── _set_visible(parent, path, val)  — internal helper
```

---

## Signal Flow

### Current (broken chain)

```
StartButton.pressed
  └─→ main_menu.gd::_on_start_pressed()
        └─→ GameManager.start_game()        ❌ identifier not found (PascalCase)
              └─→ [SCRIPT CRASHES, no game.start_game() ever runs]
```

```
EndTrigger.body_entered (in any level_XX.gd)
  └─→ _on_end_trigger_entered()
        └─→ var main = get_node_or_null("/root/Main")
              └─→ main.load_level(...)       ❌ method not found (was removed in refactor)
                    └─→ [NO-OP, player soft-locked]
```

### Target (fixed)

```
StartButton.pressed
  └─→ main_menu.gd::_on_start_pressed()
        └─→ game_manager.start_game()
              ├─→ _set_visible(MainMenu, false)
              ├─→ _set_visible(HUD, true)
              ├─→ _set_visible(TouchControls, true)
              ├─→ game_state.reset_for_level()
              ├─→ current_state = GameState.PLAYING
              └─→ await load_level("res://scenes/levels/level_01.tscn")
                    ├─→ AnimationPlayer.play("fade_out"); await animation_finished
                    ├─→ old_level.queue_free()
                    ├─→ new_level = load(path).instantiate(); add_child(new_level)
                    ├─→ game_state.reset_for_level()
                    ├─→ hud.show_level_name("Farm", 3.0)
                    └─→ AnimationPlayer.play("fade_in")
```

```
EndTrigger.body_entered (in any level_XX.gd)
  └─→ _on_end_trigger_entered()
        └─→ game_state.add_level_damage_bonus()
        └─→ game_state.current_level = N
        └─→ game_manager.load_level("res://scenes/levels/level_NN.tscn")
              └─→ (same fade/load/fade flow as above)
```

```
TouchScreenButton (any) — geometry-based
  └─→ Godot detects touch within CircleShape2D bounds
        └─→ Input.action_press(action_name)
              └─→ Input.is_action_just_pressed("jump") → player.gd triggers jump
              (no shared touch index; position determines which button fires)
```

---

## File-by-File Change Plan

### Phase 1: Fix-Only (blockers) — ~140 lines delta

| File | Action | Current state | Target state | Δ lines |
|------|--------|---------------|--------------|---------|
| `autoload/game_manager.gd` | Modify | `GameState.reset_for_level()` x2 (lines 28, 51) | `game_state.reset_for_level()` | ~2 |
| `scenes/ui/main_menu.gd` | Modify | `GameManager.start_game()` (line 72); `_input` catches both screen touch and mouse | `game_manager.start_game()`; keep `_input` (it works) | ~1 |
| `scenes/ui/touch_controls.gd` | Modify | assigns `.action` in `_ready`; no `.shape`; 2 `GameState` refs (lines 21, 26) | assigns `CircleShape2D` per button; `game_state.*` refs; null-guard for `get_window()` not needed | ~25 |
| `scenes/ui/touch_controls.tscn` | Modify | 7 buttons, `shape = null` | unchanged (shapes assigned in `.gd` per ADR-005) | 0 |
| `scenes/levels/level_01.gd` | Modify | 5 `GameState`, 1 `NarrativeDB`, `main.load_level(level_02)` | snake_case + `game_manager.load_level(level_02)` | ~4 |
| `scenes/levels/level_02.gd` | Modify | 5 `GameState`, 1 `NarrativeDB`, `main.load_level(level_03)` | snake_case + `game_manager.load_level(level_03)` | ~4 |
| `scenes/levels/level_03.gd` | Modify | 4 `GameState`, `main.load_level(level_04)` | snake_case + `game_manager.load_level(level_04)` | ~4 |
| `scenes/levels/level_04.gd` | Modify | 4 `GameState`, `main.load_level(level_05)` | snake_case + `game_manager.load_level(level_05)` | ~4 |
| `scenes/levels/level_05.gd` | Modify | 6 `GameState`, 1 `NarrativeDB`, `main.load_level(level_06)` | snake_case + `game_manager.load_level(level_06)` | ~4 |
| `scenes/levels/level_06.gd` | Modify | 5 `GameState`, `main.load_level(level_07)` | snake_case + `game_manager.load_level(level_07)` | ~4 |
| `scenes/levels/level_07.gd` | Modify | 6 `GameState`, 2 `NarrativeDB`, `main.current_state = 0` + `change_scene_to_file` | snake_case + `game_manager.return_to_menu()` | ~6 |
| `scenes/player/player.gd` | Modify | 17 `GameState` refs | snake_case | ~17 |
| `scenes/ui/hud.gd` | Modify | 6 `GameState` refs | snake_case | ~6 |
| `autoload/game_state.gd` | Modify | `_set_fury_unlocked` defined but not wired (line 10 plain var) | `var fury_unlocked: bool = false: set = _set_fury_unlocked` | ~2 |
| `project.godot` | Modify | 5 autoloads (no stretch) | 5 autoloads (no stretch — stretch stays in `game_manager.gd` per ADR-003) | 0 |
| `project.godot` [input] | Modify | 5 `InputEventScreenTouch index=0` bindings (touch collision) | remove `InputEventScreenTouch`; keep keyboard + mouse | ~-5 |
| `assets/sprites/*.png` | Create (binary) | 0 PNGs | 9 PNGs from `generate_placeholders.gd` (run once in editor) | binary |

### Phase 2: Visual Polish — ~80 lines delta

| File | Action | Δ lines |
|------|--------|---------|
| `scenes/ui/main_menu.gd` | Modify — add title fade-in tween (modulate.a 0→1 over 0.6s), subtitle delay 0.2s, button hover/press ember glow | ~25 |
| `scenes/ui/main_menu.tscn` | Modify — keep labels; stylebox already in `.gd` | ~0 |
| `scenes/ui/hud.gd` | Modify — add `_displayed_hp` field, lerp `_displayed_hp` toward `game_state.current_hp` at rate ~0.25s in `_process` | ~8 |
| `scenes/ui/hud.tscn` | Modify — add `Vignette` ColorRect with `GradientTexture2D` (0.6 alpha at top → 0 alpha at 15% height) | ~10 |
| `assets/themes/viking_theme.tres` | Create — `Theme` resource with default font, ember/ash colors | ~25 |
| `autoload/game_manager.gd` | Modify — add `return_to_menu()` method (resets state, reloads `main.tscn`) | ~6 |
| `autoload/game_manager.gd` | Modify — add stretch config in `_ready()` (per ADR-003) | ~6 |

### Phase 3: Validation — no code changes

| Task | Method |
|------|--------|
| Verify zero PascalCase autoload refs | `grep -rn "GameManager\|GameState\|NarrativeDB\|AudioManager\|CutsceneManager" --include="*.gd" \| wc -l` should be 0 |
| Verify touch shapes non-null | editor inspection of `touch_controls.tscn`; runtime: `print(btn.shape)` |
| Verify stretch applied | editor 1920x1080 + 1080x2340 viewport preview |
| Verify APK builds | `docker run robpc/godot-headless:4.3-android godot --headless --export-debug "Android" /tmp/game.apk` |
| Verify on device | install on physical Android, test menu→level01→level07 flow |

**Total estimated delta: ~220 lines** (well under 400-line PR review budget).

---

## Touch Shape Geometry

Right side (`RightControls` anchor: 1500,600 → 1900,1040; origin relative, position relative to anchor):

```
                    RightControls anchor (1500,600) ───┐
                                                       │
                          r=80                         │
                       ┌──────┐                       │
                       │ Fury │ ─────────┐             │
                       └──────┘          │            │
                                            ┌────────┐ │
                                            │  Dash  │ │
                                            └────────┘ │
                                                          ┌────────┐
                                                          │ Jump   │  r=80
                                                          └────────┘
   y=80 (top of buttons)                              x=320
                                                          (center)
                                  ┌──────────┐
                                  │ Heavy Atk│ r=80
                                  └──────────┘
                          x=300
                                  ┌──────────┐
                                  │ Light Atk│ r=80
                                  └──────────┘
                          x=180
                                                              y=200
   y=320 (bottom of buttons)
```

All right-side action buttons: **radius 80px**, centers separated by ≥120px (`Fury→Dash`, `Dash→Jump`, `Light→Heavy`, `Heavy→Jump`).

Left side (`LeftControls` anchor: 40,680 → 360,1040):

```
            LeftControls anchor (40,680) ─┐
                                          │
              ┌────────┐    ┌────────┐   │
              │  Left  │    │ Right  │   │
              │  r=60  │    │  r=60  │   │
              └────────┘    └────────┘   │
                x=60          x=200      │
                            y=200       │
                                          │
                          (320 wide, 360 tall)
```

All left-side movement buttons: **radius 60px**, centers separated by 140px (Left at x=60, Right at x=200).

---

## Color Palette Reference

| Hex | Role | Used in |
|-----|------|---------|
| `#0D0D14` | Primary dark | main_menu.tscn Background, hud vignette overlay top, level base |
| `#B2611C` | Ember accent | main_menu subtitle, button pressed border, fury tint, vignette mid |
| `#4A4A52` | Ash gray | HUD borders, secondary text, vignette bottom |
| `#F0E8DA` | Bone white | main_menu title, level name banner text, HUD labels |

| Scene | Element | Color |
|-------|---------|-------|
| **main_menu** | Background | `#0D0D14` |
| | Title | `#F0E8DA` (white-ish) |
| | Subtitle | `#B2611C` (ember) |
| | Button normal bg | `Color(0.25, 0.18, 0.1, 0.7)` (warm brown alpha) |
| | Button hover bg | `Color(0.35, 0.25, 0.15, 0.85)` |
| | Button pressed border | `#B2611C` |
| **hud** | Health bar tint_progress | `#B2611C` (ember) |
| | Health bar tint_under | `#0D0D14` (dark) |
| | Vignette top → bottom | `#0D0D14` (alpha 0.6) → transparent |
| | Fury icon modulate (active) | `#F0E8DA` (white) |
| | Fury icon modulate (cooldown) | `#4A4A52` (ash) |
| **level** | Default scene background | `#0D0D14` |
| | Player placeholder | `#4A6B8A` (from placeholder gen) |
| | Enemy placeholder | `#8B3A3A` (from placeholder gen) |
| | Boss placeholder | `#5A1A1A` (from placeholder gen) |

---

## Risk Register (Top 5)

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | Autoload rename typo leaves one PascalCase ref → silent method failure | Medium | High (game unplayable) | Run `grep -rn "GameManager\|GameState\|NarrativeDB\|AudioManager" --include="*.gd"` post-rename; expected result 0 matches (excluding `game_manager.gd` enum `GameState` which is local to the file and remains) |
| 2 | Touch shape sizes don't match real-device tap targets (Samsung Galaxy A series, Pixel) | Medium | Medium (poor UX) | Use Godot editor "Emulate Touch from Mouse" at 1080x1920 to validate visual; final test on real device in Phase 3 |
| 3 | `get_window().content_scale_*` fails or returns null in Docker headless CI | Low-Medium | Medium (CI red) | Null-guard with `if win:`; verify Docker export still passes after stretch is added (per memory #55 — the failure was on `project.godot` keys, NOT `get_window()` calls) |
| 4 | Type-hint regression: new code introduces `var x: X = $X` pattern → Android parse error on export | Low | High (export breaks) | Code review gate: no `var x: TypeName = $TypeName` pattern; use bare `@onready var x = $X`; verify APK builds in Phase 3 |
| 5 | Sprite placeholders distract from "real" game feel (rectangles look unfinished) | High | Low (cosmetic) | Communicate that placeholders are intentional in PR description; real sprite swap is a separate change (out of scope); spec already documents this is temporary |

---

## Implementation Phases

### Phase 1: Fix-Only (Blockers)

**Goal**: game is playable end-to-end on Android.

1. Rename `GameManager` → `game_manager` in `main_menu.gd` (1 line)
2. Rename `GameState` → `game_state` in `game_manager.gd` (2 lines), `hud.gd` (6), `player.gd` (17), all `level_*.gd` (~30)
3. Rename `NarrativeDB` → `narrative_db` in all `level_*.gd` (5)
4. Update `main.load_level(...)` → `game_manager.load_level(...)` in all `level_*.gd` (7)
5. In `level_07.gd`: replace `main.current_state = 0; change_scene_to_file(...)` with `game_manager.return_to_menu()`
6. Add `return_to_menu()` method to `game_manager.gd`
7. Add stretch config to `game_manager.gd _ready()` (per ADR-003)
8. Assign `CircleShape2D` to 7 buttons in `touch_controls.gd _ready()` (per ADR-005)
9. Wire `fury_unlocked` setter in `game_state.gd`
10. Remove `InputEventScreenTouch` from `project.godot` [input]
11. Run `generate_placeholders.gd` in editor, commit PNGs

**Commits**: 1 commit per logical fix (or 1-2 squashed; per D1 review budget, prefer 3 commits: rename → load_level+wiring → touch+input).

### Phase 2: Visual Polish

**Goal**: game looks Viking-themed and transitions feel intentional.

1. Add title fade-in tween to `main_menu.gd _ready()` (modulate.a 0→1 over 0.6s; subtitle 0.2s delay)
2. Add button hover/press ember glow to `main_menu.gd` (tween `self_modulate` between normal and `#B2611C` tints)
3. Add `_displayed_hp` field to `hud.gd`; lerp toward `game_state.current_hp` over ~0.25s
4. Add `Vignette` ColorRect with `GradientTexture2D` to `hud.tscn` (top 15% screen)
5. Create `assets/themes/viking_theme.tres` with default font + palette colors (optional; can be applied later)

**Commits**: 1 commit for menu + HUD vignette, 1 commit for HP lerp + theme.

### Phase 3: Validation

**Goal**: confirm 7 spec scenarios all pass on real hardware.

1. Run grep verification: zero PascalCase autoload refs
2. Run Docker headless export; confirm APK builds without errors
3. Install on Android device (or emulator)
4. Walk through acceptance criteria AC-1 through AC-8 from proposal
5. Run through all 7 levels (menu → level 07 → ending)
6. Test touch controls: tap each button, hold simultaneously, verify no cross-trigger

**Commits**: docs-only (test report in PR description).

---

## Verification Plan

### Static checks (run from repo root)

```bash
# MUST return 0 matches (excluding game_manager.gd's local enum `GameState`)
grep -rn "GameManager\|NarrativeDB\|AudioManager" --include="*.gd" | wc -l   # expect 0
grep -rn "\bGameState\b" --include="*.gd" | grep -v "autoload/game_manager.gd" | wc -l   # expect 0

# MUST return 0 matches
grep -rn "main\.load_level" --include="*.gd" | wc -l   # expect 0

# MUST return 0 matches (touches still removed)
grep -n "InputEventScreenTouch" project.godot | wc -l   # expect 0
```

### Visual checks (editor + device)

- [ ] Main menu: title text fades from invisible to full over 0.6s on `_ready`
- [ ] Main menu: subtitle text fades in 0.2s after title starts
- [ ] Main menu: button "EMPEZAR" shows ember border on hover, brighter bg on press
- [ ] HUD: dark gradient visible at top edge, fading to transparent by 15% height
- [ ] HUD: health bar smoothly decreases from 3→2 over ~0.25s on damage (not snap)
- [ ] HUD: fury icon invisible at start of game, appears at first checkpoint

### Functional checks (editor "Emulate Touch from Mouse" + device)

- [ ] Tap "EMPEZAR" → game transitions to Level 01
- [ ] Level 01 reaches end → Level 02 loads
- [ ] ... Level 06 reaches end → Level 07 loads
- [ ] Level 07 defeat boss → ending cutscene plays → return to main menu
- [ ] Tap Jump button (right side) → player jumps, no other action fires
- [ ] Hold Right button (left side) → player moves right, `move_left` does NOT fire
- [ ] Hold Right + tap Jump → both `move_right` and `jump` fire simultaneously
- [ ] On 1080x2340 device, UI scales proportionally (no off-screen elements)

### Build check (source of truth for "it works")

- [ ] `docker run --rm -v $PWD:/game robpc/godot-headless:4.3-android godot --headless --export-debug "Android" /tmp/game.apk` exits 0
- [ ] APK installs on Android device via `adb install`
- [ ] Game launches, shows main menu, plays through

---

## Migration / Rollout

**No data migration required** — all state is in-memory `GameState` autoload, reset on game start.

**Rollback plan**: each phase is a separate commit (or commit group). Revert the merge commit to restore the prior (broken) state. The autoload rename is the highest-risk change; reverting just that commit restores the previous (broken but known) state.

**Feature flag**: none needed. Stretch mode is applied unconditionally in `_ready()` with a null guard — no toggle required.

---

## Open Questions

None blocking. The proposal's open questions are deferred per the assumptions section:
- Font: bundled Viking-compatible `.ttf` (Cinel or system default)
- Palette: keep ash/ember (validated by 4-color spec table above)
- VirtualJoystick: deferred (discrete buttons fixed first)
- Docker export: tested in Phase 3, not blocking
- Narrative expansion: out of scope
- Renderer: stay `gl_compatibility`
- Stretch via `get_window()`: confirmed by ADR-003 (memory #55)
