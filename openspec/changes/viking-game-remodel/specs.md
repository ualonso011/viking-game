# Delta Specs: Viking Game Remodel

## Visual Assets

- **MODIFIED** — Illustrated PNG textures MUST be assigned to all `AnimatedSprite2D`/`Sprite2D` nodes in player, soldiers, boss, joystick, platforms, backgrounds, and UI. (Previously: placeholders.)
  - Scenario: Sprites render at runtime.
- **ADDED** — Character sprite sheets MUST be PNG frames 64–128 px high; backgrounds ≥1920×1080 px; UI power-of-two PNGs; under `assets/sprites/`.
  - Scenario: Parallax layers scroll without seams.
- **REMOVED** — Placeholder Asset Strategy. (Reason: final PNGs replace placeholders.)

## Typography

- **ADDED** — Bundle one OFL font (Cinzel or Uncial Antiqua). `viking_theme.tres` MUST set `default_font`; UI text MUST inherit it. Titles 48–72 px, subtitles/headers 24–32 px, body/buttons 16–24 px; scale down 25 % on 720p screens.
  - Scenario: Menu and HUD text uses the bundled font.

**Constraints**: OFL font only; file size < 500 KB.

## Menu System

- **MODIFIED** — Main menu MUST show one page with "EMPEZAR", "OPCIONES", "CRÉDITOS", "SALIR". Preserve title, subtitle, palette (`#0D0D14`, `#B2611C`, `#4A4A52`, `#F0E8DA`), fade-in, and hover glow. (Previously: only "EMPEZAR" existed.)
  - Scenario: Four buttons are visible/tappable; "OPCIONES" opens an inline options panel.
- **ADDED** — Options panel MUST expose Music/SFX/Ambience sliders and a fullscreen/stretch toggle; changes persist and apply through `audio_manager.gd`.
  - Scenario: Setting Music to 50 % updates the music volume.
- **ADDED** — Pause menu MUST overlay on `ui_cancel` with Resume, Options, Restart, and Menu buttons; tree stays paused.
  - Scenario: `ui_cancel` pauses and shows the panel; Resume unpauses.
- **ADDED** — Game-over screen MUST appear for ≥2 s with "Reintentar" and "Menú" options before respawn.
  - Scenario: Screen appears on death; "Reintentar" respawns at the last checkpoint.
- **ADDED** — Credits screen MUST list roles and asset attributions with a "Volver" button.
  - Scenario: Notices are visible.

## Audio

- **ADDED** — Provide four looping tracks: menu, gameplay, boss, cutscene. CC0/CC-BY with attribution; seamless loops.
  - Scenario: Gameplay music fades in on level start and loops until a boss.
- **ADDED** — SFX categories: combat (swing, hit, death), UI (click, pause, error), ambience (wind, fire, battlefield). Each category MUST expose a volume bus.
  - Scenario: A combat SFX plays on player hit.
- **ADDED** — `audio_manager.gd` MUST expose `set_music_volume`, `set_sfx_volume`, `set_ambience_volume`, `play_music/track`, `play_sfx/name`, `play_ambience/name`. Volume 0.0–1.0 mapped to dB.

## Story Completion

- **MODIFIED** — Cutscene text MUST appear in a 9-slice bottom panel, advance on tap, use the bundled font, and support a speaker portrait and background image per line. (Previously: plain black panel, no portrait/background.)
  - Scenario: Speaker "Einar" shows Einar's portrait; background cross-fades.
- **ADDED** — Add 4–6 line cutscenes for Level 03, 04, and 06 start, matching the grim narrative voice.
  - Scenario: Each level starts with its cutscene.
- **ADDED** — Each cutscene MUST play matching ambience via `audio_manager.play_ambience(name)`.
  - Scenario: L3 cutscene starts a cinder/fire ambience loop.

## UI Polish

- **MODIFIED** — HUD MUST use the ash-and-ember palette AND 9-slice wood/stone panels for health/fury containers. Health bar MUST use an ember gradient (`#B2611C` → darker red). HUD text MUST use the bundled font. Add a pause button top-right. (Previously: flat ColorRects only.)
  - Scenario: Health and fury containers render with 9-slice panels.
- **MODIFIED** — Health bar value changes MUST lerp toward target over ~0.25 s.
  - Scenario: Taking 1 damage at 3/3 HP animates the bar to 2/3 over ~0.25 s.
- **ADDED** — Replace `icon.svg` with a Viking-themed square PNG icon referenced in `project.godot`.
  - Scenario: Viking icon appears on Android.
- **ADDED** — All menus, cutscene boxes, and HUD containers MUST use 9-slice `TextureRect`/`Panel` nodes with wood/stone/leather textures under `assets/sprites/ui/`.

## Theme Integration

- **ADDED** — `assets/themes/viking_theme.tres` MUST define font, panel styles, button states, Label colors, and ProgressBar textures. All UI scenes MUST use this theme. UI surfaces MUST use `#0D0D14`, `#B2611C`, `#4A4A52`, `#F0E8DA`; no new colors without updating the theme.

**Constraints**: Theme changes MUST NOT alter gameplay logic. Style overrides SHOULD live in the theme, not per-node.
