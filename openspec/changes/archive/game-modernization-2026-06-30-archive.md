# Archive Report: game-modernization

## Final Status: ARCHIVED

**Date Archived**: 2026-06-30
**Change Name**: game-modernization
**Archived To**: `openspec/changes/archive/game-modernization-2026-06-30/`

---

## Executive Summary

Fixed three critical blockers that made the game completely unplayable on Android: (1) autoload name casing mismatch — 83+ PascalCase references replaced with snake_case; (2) all 7 TouchScreenButton shapes were null — touch input never registered; (3) level end-triggers called a removed `main.load_level()` — players soft-locked after every level. Applied Viking-themed visual modernization including menu animations, HUD vignette, and smooth health bar interpolation. CI builds successfully. One manual follow-up remains: placeholder sprite generation requires x86_64 Godot editor.

---

## What Shipped

### Blocker Fixes (Phase 1)
- **Autoload casing**: Renamed all `GameManager`/`GameState`/`NarrativeDB` PascalCase references to `game_state`/`game_manager`/`narrative_db` across ~10 scripts (~83 replacements)
- **Level transitions**: Updated all 7 level scripts from `main.load_level()` → `game_manager.load_level()`. Level 07 ending now uses `game_manager.return_to_menu()`
- **Touch shapes**: Assigned `CircleShape2D` to all 7 `TouchScreenButton` nodes (action: r=80px, movement: r=60px). Removed `InputEventScreenTouch` from Input Map
- **Fury setter**: Wired `_set_fury_unlocked` setter in `game_state.gd`
- **Stretch mode**: Added runtime `get_window().content_scale_*` configuration in `game_manager.gd _ready()` (null-safe for CI)

### Visual Modernization (Phase 2)
- **Viking theme**: Created `viking_theme.tres` with ash-and-ember palette (#0D0D14, #B2611C, #4A4A52, #F0E8DA)
- **Menu animations**: Title fade-in tween (modulate.a 0→1, 0.6s), subtitle delay 0.2s, button hover/press ember glow
- **HUD polish**: Smooth HP lerp (`_displayed_hp` with exp decay), vignette gradient overlay (top 15% screen, #0D0D14 alpha 0.6→0)

---

## Git Commits

| Commit | Message | Phase |
|--------|---------|-------|
| `2c440ec` | `fix(blockers): autoload casing + level transitions + touch shapes + stretch config` | Phase 1 |
| `eaafb5f` | `feat(polish): Viking theme + menu animations + HUD vignette` | Phase 2 |

---

## Specs Archived (7 total)

| Domain | Action | Requirements Added |
|--------|--------|--------------------|
| autoload-names | Created | 1 requirement, 3 scenarios |
| level-load-calls | Created | 1 requirement, 3 scenarios |
| touch-shapes | Merged into touch-controls | 2 requirements, 3 scenarios |
| sprite-assets | Created | 3 requirements, 3 scenarios |
| stretch-mode | Created | 3 requirements, 3 scenarios |
| main-menu | Created | 3 requirements, 3 scenarios |
| hud-modernization | Merged into hud-system | 3 requirements, 3 scenarios |

### Merged Domains

- **touch-controls**: Added "Non-Null Touch Shapes" and "Button Shape Sizes" requirements from delta `touch-shapes`
- **hud-system**: Added "HUD Color Palette", "Top Vignette Gradient", and "Smooth Health Bar Interpolation" requirements from delta `hud-modernization`

---

## Archive Contents

```
openspec/changes/archive/game-modernization-2026-06-30/
├── apply-progress.md     ✅
├── design.md             ✅
├── explore.md            ✅ (optional)
├── proposal.md           ✅
├── specs/                ✅ (7 domain subdirectories)
├── tasks.md              ✅ (22/22 tasks reconciled, 1 manual follow-up deferred)
└── verify-report.md      ✅
```

---

## Source of Truth Updated

The following specs now reflect the new behavior:
- `openspec/specs/autoload-names/spec.md` — new domain
- `openspec/specs/level-load-calls/spec.md` — new domain
- `openspec/specs/touch-controls/spec.md` — merged with touch-shapes delta
- `openspec/specs/sprite-assets/spec.md` — new domain
- `openspec/specs/stretch-mode/spec.md` — new domain
- `openspec/specs/main-menu/spec.md` — new domain
- `openspec/specs/hud-system/spec.md` — merged with hud-modernization delta

---

## Build & Verification

- **CI Run**: https://github.com/ualonso011/viking-game/actions/runs/28438225257
- **Workflow**: Build Android APK
- **Conclusion**: success
- **APK Artifact**: `LasCenizasDelOso-Android` — 24,098,188 bytes (~23 MB)
- **Specs verified**: 7/7
- **Scenarios verified**: 18/18
- **Static checks**: All PASS (zero PascalCase refs, zero main.load_level, zero InputEventScreenTouch)

---

## Follow-Up Items

1. **Placeholder sprite generation (manual)**: Task 1.11 blocked on aarch64 host. Run `generate_placeholders.gd` in Godot editor on x86_64 to generate 9 placeholder PNGs in `assets/sprites/`. Verify player, soldier, and boss sprites are visible at runtime.
2. **Dead guard code cleanup**: All 7 level scripts contain `var main = get_node_or_null("/root/Main"); if main and main.has_method("load_level"):` — the `has_method("load_level")` check is always false since `main` no longer has that method. Harmless but misleading dead code should be removed.
3. **Comment-only PascalCase refs**: `level_07.gd:67` and `main.gd:2` still reference PascalCase names in comments. Not code, but contradicts "zero PascalCase references" spec language.
4. **Bundled font**: `viking_theme.tres` has `default_font = null` — no `.ttf`/`.otf` file is bundled. Consider adding a free Viking-compatible font (Cinel, Uncial Antiqua).
5. **Touch shape sharing**: All 5 right-side buttons share the same `CircleShape2D` instance. Works for detection but means per-button shape customization would require `.duplicate()`.
6. **Double reset in level_07**: `level_07.gd` calls `game_state.reset()` then `game_manager.return_to_menu()`, which already calls `game_state.reset()` internally. Redundant but harmless.

---

## Lessons Learned

- **Autoload naming is a silent killer**: PascalCase vs snake_case mismatch in Godot autoloads causes method calls to silently fail with no error at runtime. Always grep for the registered name, not the convention you expect.
- **TouchScreenButton without shape = dead input**: Godot silently ignores touches on buttons with null shapes. This is a common gotcha for Android touch games — always assign shape resources in code, not just in the scene tree.
- **Runtime stretch > project.godot stretch**: `project.godot` stretch settings break Docker CI headless export. Using `get_window().content_scale_*` at runtime with a null guard is the safe approach for CI-friendly builds.
- **aarch64 vs x86_64 Godot binaries**: Godot editor binaries are architecture-specific. CI on GitHub Actions (x86_64) works; local aarch64 hosts cannot run the same binary. Plan asset generation around this constraint.
