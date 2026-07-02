# Exploration: viking-game-remodel

## Status: ready for propose

The game **technically works** (blockers were fixed in the prior `game-modernization`
change archived 2026-06-30), but visually and structurally it's still a "colored
rectangles on a dark background" prototype. The user wants a full **remodel** —
modern menus, real visual identity, polished UI, proper game-feel.

## Executive Summary

**Las Cenizas del Oso** is a Godot 4 (GDScript) 2D narrative action-platformer
for Android. The game tells the story of Einar, a Viking farmer who becomes the
warrior "El Oso de Ceniza" (The Ash Bear) after his village is destroyed by
Jarl Halvard, and ends in tragedy when he unknowingly kills his own son in
final combat on the ash battlefield.

**What works:** Core gameplay loop (move, jump, light/heavy attack, dash, Furia
del Oso ability), 7 levels with checkpoints, 2 boss fights, 5 cutscenes with
narrative dialogue, Android export pipeline via GitHub Actions (last CI run
produced a valid ~23 MB APK).

**What doesn't work / looks broken:**
- **Zero visual assets** — every AnimatedSprite2D has `sprite_frames = null`,
  every Sprite2D has `texture = null`. The player, soldiers, boss, joystick
  knob are all invisible. Levels are just colored ColorRects.
- **No bundled font** — every label uses Godot's default bitmap font. The
  viking theme is conceptual (palette + copy) but typographically absent.
- **Placeholder palette** — "ash and ember" `#0D0D14` / `#B2611C` / `#4A4A52`
  / `#F0E8DA` is defined in `viking_theme.tres` and applied as ColorRects,
  but there is zero texture work — every surface is a flat rectangle.
- **Menus are bare** — main menu is a single "EMPEZAR" button on a dark
  background. No options, no credits, no pause menu, no game-over screen.
- **Audio is fully stubbed** — `audio_manager.gd` has 18 lines of empty
  methods. No music, no SFX.
- **No custom icon** — `icon.svg` is a default "O" letter on dark background.
- **No save/load** — every run starts fresh from level 1.
- **Touch shapes assigned in code, not scene** — works at runtime, but the
  `.tscn` still shows `shape = null` for all 7 TouchScreenButtons, which is
  misleading when reading the scene file and could break if someone removes
  the `_ready()` shape assignment.

The user wants this remodeled — proper menus, real visual identity, sound,
polish. The architecture is sound, the logic works, the game is **mechanically
complete** (7 levels, 2 bosses, 5 cutscenes, all wired up). What it needs is
the **visual and UX layer** that turns a tech demo into a shippable Android game.

## Story / Plot

**Title:** Las Cenizas del Oso (The Ashes of the Bear)
**Setting:** Medieval Scandinavia + Anglo-Saxon England
**Protagonist:** Einar — a simple farmer of the northern fjords
**Antagonists:** Jarl Halvard (corrupt Norse jarl allied with the English king) +
the final-boss son (forced into the English king's service)
**Arc:**
1. **Farm (L1)** — Einar returns from a hunt. Village burning. Family gone.
   Survivor names Jarl Halvard. "From the ashes, a bear arose."
2. **Exile / Burned Forest (L2)** — Einar follows Halvard's trail. The forest
   is scarred. He reflects on his losses.
3. **Cinders / Ruined Village (L3)** — Generic combat level, no story trigger.
4. **Warpath / Snowy Mountains + Fort (L4)** — Generic combat level.
5. **Jarl's Hall (L5)** — Confronts Halvard. Reveals Einar's son was taken
   south to England. They fight.
6. **England Invasion (L6)** — Generic combat level, no story trigger.
7. **Ash Battlefield (L7)** — Final boss is Einar's own son in black armor,
   raised by the English king. They fight. Einar wins. The son dies in his
   arms calling him "Father." No victory. Only ashes.

**Narrative quality:** The voice is good — spare, grim, poetic. The arc is
strong. **But it's under-delivered**: levels 3, 4, 6 have no cutscenes, so
the middle of the story is just "kill soldiers, walk right." The "father
kills son" reveal lands hard because levels 5 and 7 are well-scripted, but
the connective tissue is missing.

## Game Structure

**Linear 7-level campaign.** Each level is a self-contained `.tscn` with
manually placed StaticBody2D platforms (NOT a TileMap — `TileMapLayer` was
called out in the design but never actually used; the implementation uses
ColorRects + StaticBody2D per platform), an instanced Player, 2-8 instanced
Soldiers, optional Boss, one Checkpoint Area2D, and one EndTrigger Area2D.

| Level | Theme | Enemies | Cutscenes | Special |
|-------|-------|---------|-----------|---------|
| 01 | Farm | 2 soldiers | `intro_farm` (7 lines) | Fury unlocked at checkpoint |
| 02 | Burned forest | 4 soldiers | `exile_forest` (5 lines) | — |
| 03 | Cinders | 5 soldiers | — | — |
| 04 | Warpath / mountains | 6 soldiers | — | max_hp+1 on end |
| 05 | Jarl's Hall | 2 soldiers + Halvard boss | `before_halvard` (8 lines) | Boss has 3 phases |
| 06 | England invasion | 8 soldiers | — | max_hp+1 on end |
| 07 | Ash battlefield | Final boss (25 HP) | `final_boss_intro` + `final_boss_defeat` (6+8 lines) | max_hp+1 on end, return to menu |

**Progression:** Linear via EndTrigger → `game_manager.load_level(next)`.
Death loops back to last checkpoint (or level start after 3 deaths at same
checkpoint). Stats scale per level: `base_damage += 0.5` per level cleared,
`max_hp += 1` at story milestones (4, 5, 6, 7).

**Fury del Oso:** Unlocked at L1 checkpoint. 5s duration, +50% damage, 30s
cooldown. Visually represented by red tint on the player sprite (modulate).

## Menus & UI

**Current state of every menu:**

1. **Main Menu** (`scenes/ui/main_menu.tscn`)
   - 1 button: "EMPEZAR" (Start)
   - 2 labels: title "LAS CENIZAS DEL OSO" + subtitle "Un viaje vikingo de ceniza y acero"
   - Background: solid `Color(0.05, 0.05, 0.08)` dark
   - Animations: title fade-in tween, subtitle 0.2s delayed, button hover/press glow
   - **Missing:** settings, audio toggle, credits, language, new game/continue distinction, exit

2. **HUD** (`scenes/ui/hud.tscn`)
   - Health bar: 184x24 TextureProgressBar top-left, red tint, smooth lerp
   - Fury icon: 64x64 top-right, TextureProgressBar radial fill for cooldown
   - Level name: top-center, 3s fade
   - Checkpoint banner: center-screen, 2s fade
   - **Missing:** score, lives, mini-map, ability hotkeys, dialogue skip indicator

3. **Cutscene** (`scenes/cutscene/cutscene_manager.tscn`)
   - Bottom panel 1600x200, 80% black, white text, "Tap to continue" hint
   - `process_mode = PROCESS_MODE_WHEN_PAUSED` (works correctly)
   - **Missing:** speaker portrait, scene background, sound, choice/input pacing

4. **Pause Menu** — **DOES NOT EXIST**
   - `game_manager._unhandled_input` listens for `ui_cancel` and toggles
     `get_tree().paused`, but no pause UI is shown. The player can pause the
     game and have no way to resume except pressing Esc again blind.

5. **Game Over Screen** — **DOES NOT EXIST**
   - On death, the player respawns after 2s with no feedback. No "You Died"
     screen, no retry/quit choice.

6. **Settings Screen** — **DOES NOT EXIST**

7. **Credits Screen** — **DOES NOT EXIST**

8. **Main Menu background art** — solid color only. No logo, no mountain
   silhouette, no Viking ship, no runic decoration.

## Viking Theme Assessment

**Conceptual execution:** Strong. The narrative voice is committed, the
palette is intentionally grim (ash + ember, not "viking = horned helmets and
mead halls"), and the game earns its tragedy.

**Visual execution:** Almost nonexistent. Zero textures, zero pixel art,
zero Viking iconography. The "vikingness" is communicated entirely through
**text** (the title, the subtitle, the dialogue) and **color choices** (the
ember palette). A player who can't read Spanish or who only sees the
gameplay would not know it's a Viking game.

**What a Viking game should have that this doesn't:**
- Runic typography or Norse-inspired font (currently uses Godot default)
- Wood/stone/leather texture on platforms (currently flat ColorRects)
- Longship or Norse architecture in menu backdrop
- Authentic Nordic color sub-palette (deep ocean blue, blood red, bronze)
- Ambient sounds (wind, fire, distant drums) — completely silent
- Music — completely silent

**What it does have that works for the theme:**
- The "ash and ember" palette is mature and avoids the trap of cartoon
  vikings
- The story's grim tone matches the visual minimalism (in a "less is more"
  way, the void is on-theme)
- The Furia del Oso red-tint effect feels visceral when it works

## Code Quality

**Architecture:** Solid. The Godot 4 conventions are followed:
- Autoloads for cross-scene state (game_state, game_manager, narrative_db,
  audio_manager, cutscene)
- Feature-grouped scenes (not type-segregated)
- Signal-based event handling
- CharacterBody2D + Area2D for physics
- Custom VirtualJoystick Control (though unused — see below)

**Strengths:**
- `player.gd` flat state machine is clean and readable (321 lines, well
  commented, good separation of movement / combat / dash / fury / hurt)
- `soldier.gd` and `boss.gd` AI is sensible (timer-based ticks,
  VisibleOnScreenNotifier2D for CPU savings, phase-based boss)
- `game_state.gd` and `game_manager.gd` are small, focused, well-typed
- `narrative_db.gd` cleanly separates dialogue data from presentation
- The cutscene system correctly uses `PROCESS_MODE_WHEN_PAUSED` so it works
  while the game tree is paused
- VisibleOnScreenNotifier2D on enemies is a nice mobile-CPU optimization
- Death-respawn loop guard (3 deaths at same checkpoint → respawn at level
  start) is a thoughtful softlock prevention

**Weaknesses:**
- 7 level `.gd` files have heavy copy-paste duplication (every level
  repeats the checkpoint handler, end-trigger handler, show_level_name call).
  Could be DRY'd with a base class.
- 7 level `.tscn` files have heavy duplication of the same ColorRect +
  StaticBody2D + RectangleShape2D pattern. A `level_base.tscn` with
  parameter override would help.
- `main.gd:2` still has PascalCase "GameManager" in a comment (harmless,
  misleading).
- `level_07.gd` does `game_state.reset()` then `game_manager.return_to_menu()`
  which itself does `game_state.reset()` — double reset, harmless.
- `virtual_joystick.gd` is a complete 82-line implementation that is
  **never instantiated anywhere** — touch_controls.tscn uses discrete
  `TouchScreenButton`s (Left/Right) for movement instead. Dead code.
- `audio_manager.gd` is 18 lines of `pass` stubs. Wasted file.
- `cutscene_manager.gd` is missing speaker portraits, scene backgrounds,
  and any audio cue. Spec mentioned "camera movement during scenes" but
  it's not implemented (and isn't needed for the current fixed-camera
  design).
- `player.gd` has a duplicate `if state == State.DASH: return` check in
  `take_damage()` (lines 224 AND 226). Dead branch.
- `game_state._set_fury_unlocked` setter is correctly wired now (per the
  prior change), but the level scripts that set `fury_unlocked = true`
  (level_01.gd:42) bypass the setter pattern — they set the field directly
  AND manually emit `fury_unlocked_changed.emit()` on the next line. Inconsistent.
- `level_07.gd` overrides `boss.max_hp = 25` etc. from the level script
  instead of using a level-specific boss scene. The Final Boss is the same
  `boss.tscn` as Halvard with different stats. Works, but a `boss_final.tscn`
  would be cleaner.
- `cutscene_manager.gd:38` uses `get_tree().create_timer(INPUT_DELAY, true, false, true)`
  — the 4-argument signature with `process_always=true` is correct for a
  timer that should tick while paused, but it's non-obvious. A comment
  explaining would help.
- `main_menu.gd:99` calls `game_manager.start_game()` from both
  `button_down` AND `button_up` signals (lines 12-13) — so the function is
  called twice on every press. The second call is a no-op because
  `current_state != MENU`, but it's wasteful and confusing.
- `main_menu.gd:37-41` has a catch-all `_input` that calls
  `_on_start_pressed()` on ANY screen touch or mouse click — meaning tapping
  ANYWHERE on the menu starts the game. This is intentional ("big touch
  target") but the same logic should probably be guarded so it doesn't
  trigger when the menu is fading out.

**Style:**
- GDScript style is consistent (type hints, `@onready`, snake_case vars)
- `##` doc comments on most scripts
- Naming is mostly consistent (snake_case for files, PascalCase for class
  names, but classes don't have `class_name` declarations)
- `enum State { ... }` is fine; bigger projects would push toward State
  pattern but 9 states here doesn't justify it

**Build / CI:**
- Dockerfile is functional but has fallback chains (line 28-31, 34-35) that
  mask real errors
- GitHub Actions workflow is well-tuned (CI green last run, APK 23 MB)
- `export_presets.cfg` has `package/signed=true` but no real release
  keystore — fine for debug builds, will fail for Play Store

## Current Problems (ranked by severity)

### Critical (game looks broken)
1. **No sprite assets** — all 5 AnimatedSprite2D nodes have `sprite_frames = null`,
   all 3 Sprite2D nodes have `texture = null`. The player, all soldiers, the
   boss, and the joystick knob are INVISIBLE. The only thing visible is
   ColorRects (background, platforms, walls, checkpoint marker, end marker).
2. **No bundled font** — every label uses Godot's default bitmap font, which
   is sterile and inconsistent. `viking_theme.tres` even sets
   `default_font = null`. The "viking" identity is purely typographic wishful
   thinking.
3. **No icon** — `icon.svg` is a brown "O" on dark brown. Doesn't ship well
   to Play Store.

### High (game is incomplete)
4. **No pause menu** — pressing Esc pauses the game but shows nothing.
5. **No game-over screen** — death = 2s respawn with no feedback.
6. **No settings screen** — no audio toggle, no difficulty, no language.
7. **No main menu polish** — single "EMPEZAR" button, no options, no
   credits, no logo.
8. **No audio** — `audio_manager.gd` is all stubs. No music, no SFX.
9. **Levels 3, 4, 6 have no story** — they're just "kill X soldiers, walk
   right." The middle of the narrative is missing.

### Medium (polish issues)
10. **Touch shapes assigned in code, not scene** — works at runtime but the
    `.tscn` shows `shape = null` for all 7 buttons. Misleading for scene
    editing.
11. **VirtualJoystick is dead code** — 82 lines of implementation never used.
12. **Duplicate main_menu button signals** — both `button_down` and
    `button_up` call `_on_start_pressed()`.
13. **Catch-all menu _input** — tapping anywhere on the menu starts the game.
14. **Comment-only PascalCase** — `main.gd:2` and `level_07.gd:67` still
    mention `GameManager` in comments.
15. **Double reset in level_07** — `game_state.reset()` + `game_manager.
    return_to_menu()` which itself resets.
16. **player.gd duplicate DASH check** — `take_damage` checks `state == DASH`
    twice on consecutive lines.
17. **Level scripts bypass fury setter** — `level_01.gd:42` sets
    `fury_unlocked = true` directly instead of using the setter (which would
    auto-emit the signal).
18. **No save/load** — every run is from level 1.
19. **No background art** — menus are flat dark color, no logo, no scenery.

### Low (nice to have)
20. **All levels use the same `boss.tscn`** — Halvard and the Final Boss are
    the same scene with different stats.
21. **No cutscene speaker portraits** — text is the only cutscene element.
22. **No ambient particles** — no fire, ash, snow, or rain effects.
23. **No death animation variety** — every enemy death is `queue_free`
    after 1-2s.
24. **No parallax art in levels** — `level_01.tscn` has a `ParallaxBackground`
    but the `BgLayer` is empty (no parallax content, just a ColorRect).

## Affected Areas

| Path | State | Notes |
|------|-------|-------|
| `assets/sprites/` | MISSING | Only `generate_placeholders.gd` exists; no PNGs generated |
| `assets/themes/viking_theme.tres` | PARTIAL | Palette defined; `default_font = null` |
| `assets/fonts/` | MISSING | No fonts directory at all |
| `scenes/player/player.tscn` | BROKEN | `texture = null`, `sprite_frames = null` |
| `scenes/enemies/soldier.tscn` | BROKEN | `sprite_frames = null` |
| `scenes/enemies/boss.tscn` | BROKEN | `sprite_frames = null` |
| `scenes/ui/virtual_joystick.tscn` | BROKEN | `Base.texture = null`, `Knob.texture = null`; scene is orphaned |
| `scenes/ui/virtual_joystick.gd` | DEAD | Never instantiated; touch_controls uses TouchScreenButtons |
| `scenes/ui/main_menu.tscn` | BARE | 1 button, no options/credits/settings |
| `scenes/ui/hud.tscn` | BARE | Functional but minimal — no pause menu |
| `scenes/cutscene/cutscene_manager.tscn` | BARE | Text panel only, no portrait, no scene background |
| `autoload/audio_manager.gd` | STUB | All 4 methods are `pass` |
| `scenes/ui/touch_controls.tscn` | HALF | Shapes assigned in code, not scene |
| `scenes/main/main.gd:2` | COMMENT | "GameManager" mentioned in docstring |
| `scenes/levels/level_07.gd:67` | COMMENT | "GameManager" mentioned in comment |
| `icon.svg` | DEFAULT | Brown "O" letter; not viking-themed |
| `scenes/levels/level_01-07.gd` | DUPLICATE | Heavy copy-paste; could share a base class |
| `scenes/levels/level_01-07.tscn` | DUPLICATE | ColorRect+StaticBody2D pattern repeated 7 times |
| `scenes/levels/level_03,04,06` | NO-STORY | No cutscenes; narrative arc has 3 holes |

## Approaches

### Approach A: Visual-only remodel (replace placeholders with real assets)
Generate real pixel-art sprites for player/soldiers/boss/platforms, bundle a
Viking-themed font, redo the menu/HUD/cutscene styling with proper 9-slice
panels, draw a real icon. Keep all logic the same. Ship the same 7-level
game but make it look like an actual game.

- **Pros:** Single focused change, no risk to working logic, biggest UX win
  for effort, can be done by an asset-pipeline (generate PNGs from a tool,
  no artist needed)
- **Cons:** Still no audio, still no pause menu, still no options, levels
  3/4/6 still have no story
- **Effort:** Medium (~4-6 hours, mostly asset generation + scene restyling)

### Approach B: Full visual + UX remodel (recommended)
Approach A + complete the missing UI (pause menu, game-over screen, options
screen, settings, credits) + add a real audio_manager with placeholder
music/SFX slots + write 3 missing cutscenes (levels 3, 4, 6) + bundle a
free Viking font + redesign the main menu with logo + add 9-slice wood/
stone panel textures for UI surfaces. Logic untouched.

- **Pros:** Single deliverable that turns a tech demo into a presentable
  Android game. All known gaps closed. Matches the user's stated goal
  ("redo it completely, with modern menus").
- **Cons:** Larger scope (~10-14 hours), more files touched (~30+), needs
  free asset sources identified upfront
- **Effort:** Medium-High

### Approach C: Phased remodel (3 PRs)
- PR 1: Asset pipeline (sprites + font + 9-slice panels) — game looks like a game
- PR 2: Complete UI (pause, game-over, options, settings, credits, audio) — game is shippable
- PR 3: Story completeness (3 cutscenes, dialogue refinement, narrative arc polish)

- **Pros:** Each PR independently shippable, lower risk per PR, easy to
  review
- **Cons:** 3x SDD ceremony overhead, user has to wait for full remodel,
  partial work in main for 3 cycles
- **Effort:** Medium-High (due to overhead)

## Recommendation

**Approach B — Full visual + UX remodel in a single coordinated change.**

Rationale:
- The user explicitly said "redo it completely" and mentioned menus
  (plural). They want a finished-looking game, not a 3-PR iterative remodel.
- The mechanical work (generate sprites, bundle font, restyle UI) is
  non-architecturally-risky. We're swapping visual layer; logic stays.
- The SDD artifacts (spec, design, tasks) document everything cleanly, so
  even a ~1000-line change is reviewable.
- Chained PRs make sense IF the change exceeds 400 lines AND is logically
  separable. Here, assets + UI + audio + cutscenes are all interconnected
  (new HUD elements reference new font, new menu references new audio,
  etc.), so splitting into PRs adds integration risk without value.

The 400-line budget is a soft guideline, not a hard limit. Approach B
will likely be 800-1200 lines, which is appropriate for a complete
visual remodel. We should split into chained PRs ONLY if the user
prefers incremental delivery.

## Open Questions

1. **Font choice** — bundle a free Viking-compatible font (Cinzel, Uncial
   Antiqua, Norse Bold) or use Godot's default with a heavier weight? The
   free font route is more "viking" but adds asset weight (~100-500 KB).
2. **Sprite style** — pixel art (16-bit retro, fits a platformer) or
   hand-drawn / illustrated (more emotional, fits the tragic story)?
   Pixel art is easier to generate procedurally; illustrated needs an
   artist or AI image gen with manual cleanup.
3. **Menu structure** — single page (Start / Options / Credits / Exit) or
   two-page (Main / Settings)? Both are fine; the single-page approach
   is more modern and discoverable.
4. **Audio strategy** — generate placeholder music via procedural
   tools (sfxr, Bosca Ceoil) or use Creative Commons assets from
   OpenGameArt? Procedural is free, CC assets are higher quality.
5. **Story scope** — should the remodel add 3 new cutscenes for levels
   3/4/6, or is the user happy with the story as-is (with the holes)?
   The existing narrative voice in `narrative_db.gd` is good; matching
   it requires care.
6. **Pause menu** — simple overlay or full screen takeover?
7. **Game over screen** — "retry from checkpoint" or "retry from level
   start" or both?
8. **Save system** — add basic save (last unlocked level, fury state) or
   keep it always start from level 1?
9. **Background art** — draw or generate a parallax mountain/fjord
   backdrop, or keep flat ColorRect? (Parallax was started in
   level_01 but never finished.)
10. **Animation priority** — even with placeholder sprites, do we want
    procedural animations (color modulation, tween bounces) on existing
    elements to make the game feel responsive before real sprites ship?

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Free font has restrictive license | Low | Low | Use Cinzel (OFL) or Uncial Antiqua (OFL) — both CC-compatible |
| Generated sprites look amateurish | Medium | Medium | Iterate on the generator script; commit PNGs that are "good enough" |
| Audio assets have license issues | Low | Medium | Stick to OpenGameArt CC0 / CC-BY assets, document attribution |
| Adding pause/settings/main-menu backends breaks existing flow | Low | High | Add new scenes, don't modify main_menu.tscn internals — use composition |
| Touch shape code-assignment regression if someone edits the scene | Medium | Low | Move shape assignment back into the `.tscn` as `[sub_resource]` definitions |
| New cutscenes for L3/4/6 don't match existing voice | Medium | Low | Hand them off to the user for review, or write in same minimalist style |
| Scope creep → exceeds SDD budget | Medium | Medium | Use chained PRs ONLY if 400-line budget is firm; otherwise deliver as one change |

## Next Steps

1. **Proceed to `sdd-propose`** with Approach B (full visual + UX remodel).
2. The proposal should scope: asset pipeline (sprites + font + 9-slice
   panels), complete UI (pause, game-over, options, settings, credits,
   audio), 3 missing cutscenes, main menu redesign, real icon.
3. Resolve the open questions (1-10 above) before writing the spec.
4. Estimate line count: probably 1000-1500 lines across ~25-35 files.
   If 400-line budget is hard, split into PR 1 (assets + main menu) →
   PR 2 (HUD + cutscene + settings) → PR 3 (audio + missing cutscenes).
5. Test data: use `sdd-init` testing capabilities to confirm no GDScript
   test framework is available — visual remodel can't have automated
   regression, only manual playtest in Godot editor + APK on device.
