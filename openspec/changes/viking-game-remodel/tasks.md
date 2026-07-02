# Tasks: Viking Game Remodel

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1450 (4 PRs: 350 + 250 + 400 + 450) |
| 400-line budget risk | High (PR 4 exceeds at ~450) |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 (feature-branch-chain) |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Asset pipeline: fonts, sprites, 9-slice, icon | PR 1 | Base branch; no logic changes |
| 2 | Audio system + theme application | PR 2 | Targets PR 1 branch; bus rewrite + theme .tres |
| 3 | Menu UI surfaces (pause/gameover/options/credits) | PR 3 | Targets PR 2 branch; 4 new scenes + game_manager wiring |
| 4 | Cutscenes + LevelBase refactor (all 7 levels) | PR 4 | Targets PR 3 branch; exceeds 400-line budget — needs size:exception |

---

## PR 1: Asset Pipeline (~350 lines)

Branch: `feature/viking-remodel-assets`

### Phase 1.1 — Fonts

- [x] 1.1.1 Download Cinzel-Regular.ttf, Cinzel-Bold.ttf, UncialAntiqua-Regular.ttf into `assets/fonts/`
- [x] 1.1.2 Add `assets/fonts/FONT_LICENSE.txt` (OFL 1.1 text)
- [x] 1.1.3 Create `.import` hints: set `font_data/antialiasing = 1` per font to avoid Godot 4.3 warnings

### Phase 1.2 — Sprite Generation

- [x] 1.2.1 Rename `assets/sprites/generate_placeholders.gd` → `generate_assets.gd`
- [x] 1.2.2 Add player sprite functions: idle, run (4-frame strip), attack_light, attack_heavy, jump, dash, hurt, dead — 64px height, palette-tinted
- [x] 1.2.3 Add enemy sprite functions: soldier idle/run/attack/hurt/dead (32px), boss_halvard idle/enraged (48px), boss_final idle/enraged (48px)
- [x] 1.2.4 Add 9-slice panel generators: `panel_wood.png` (64x64, 32px frame), `panel_stone.png` (64x64, 32px frame)
- [x] 1.2.5 Add portrait generators: narrator, einar, halvard, young_warrior, english_soldier (128x128)
- [x] 1.2.6 Add background generators: farm_burning, cinders_village, snowy_mountains, english_coast (1920x1080)
- [x] 1.2.7 Add UI sprite generators: fury_icon, checkpoint_flag, health_bar_bg/fill (ember gradient)
- [x] 1.2.8 Run `generate_assets.gd` via editor; verify all PNGs created under `assets/sprites/`

### Phase 1.3 — Theme Resources

- [x] 1.3.1 Create `assets/themes/panel_wood.tres` — StyleBoxTexture, 9-slice from panel_wood.png
- [x] 1.3.2 Create `assets/themes/panel_stone.tres` — StyleBoxTexture, 9-slice from panel_stone.png
- [x] 1.3.3 Create `assets/themes/viking_theme.tres` — default_font=Cinzel, font_size=18, button StyleBoxTexture refs, label color=#F0E8DA, outline enabled

### Phase 1.4 — Icon + Scene Assignment

- [x] 1.4.1 Generate `assets/sprites/icon.png` (192x192, Thurisaz rune ᚦ); update `project.godot` config/icon path
- [x] 1.4.2 Assign player sprite frames in `scenes/player/player.tscn` (AnimatedSprite2D → new PNGs)
- [x] 1.4.3 Assign soldier sprite frames in `scenes/enemies/soldier.tscn`
- [x] 1.4.4 Assign boss sprites in `scenes/enemies/boss.tscn` (idle + enraged)
- [x] 1.4.5 Replace ColorRect platforms with Sprite2D (panel_wood texture) in all 7 `level_*.tscn`

**Verify**: Godot editor opens without errors; each level renders sprites; APK build succeeds.

---

## PR 2: Audio + Theme (~250 lines)

Branch: `feature/viking-remodel-audio` (base: PR 1)

### Phase 2.1 — Audio Bus Config

- [x] 2.1.1 Add audio bus layout to `project.godot`: Master, Music (-6dB), SFX (0dB), Ambience (-10dB)

### Phase 2.2 — Audio Manager Rewrite

- [x] 2.2.1 Rewrite `autoload/audio_manager.gd`: add MusicPlayer, AmbiencePlayer (looping), SFXPool (8× round-robin)
- [x] 2.2.2 Implement `play_music(track, loop)` with cross-fade tween (0.5s)
- [x] 2.2.3 Implement `play_sfx(name)` via SFX pool round-robin
- [x] 2.2.4 Implement `play_ambience(track)` / `stop_ambience(fade_ms)`
- [x] 2.2.5 Implement `set_bus_volume(bus, linear)` / `get_bus_volume(bus)` — 0.0–1.0 → dB conversion
- [x] 2.2.6 Add signals: `music_finished`, `bus_volume_changed(bus, linear)`

### Phase 2.3 — Audio Assets + Attribution

- [x] 2.3.1 Add 4 music OGGs: menu_theme, farm_ambient, halvard_boss, ash_battlefield → `assets/audio/music/`
- [x] 2.3.2 Add 8 SFX OGGs: sword_light/heavy, hit_player/enemy, ui_click/hover, checkpoint, death → `assets/audio/sfx/`
- [x] 2.3.3 Add 3 ambience OGGs: wind, fire_crackle, rain → `assets/audio/ambience/`
- [x] 2.3.4 Create `assets/audio/ATTRIBUTION.md` (CC0/CC-BY credits)
- [x] 2.3.5 Add license texts to `assets/licenses/`

### Phase 2.4 — Theme Application

- [x] 2.4.1 Apply `theme = preload("res://assets/themes/viking_theme.tres")` in `main_menu.gd._ready()`; remove `_style_button()` and `add_theme_color_override()` calls
- [x] 2.4.2 Apply theme in `hud.gd._ready()`; remove hardcoded color overrides from `hud.tscn`
- [x] 2.4.3 Apply theme in `touch_controls.gd._ready()`
- [x] 2.4.4 Apply theme in `cutscene_manager.gd._ready()`

**Verify**: Music/SFX/ambience play in dev; options sliders adjust bus volume live; all UI uses Cinzel font.

---

## PR 3: Menu UI (~400 lines)

Branch: `feature/viking-remodel-menus` (base: PR 2)

### Phase 3.1 — Main Menu Extension

- [ ] 3.1.1 Add 3 buttons to `main_menu.tscn`: OptionsButton, CreditsButton, ExitButton
- [ ] 3.1.2 Update `main_menu.gd`: wire Options→options_panel.show(), Credits→credits_panel.show(), Exit→quit()
- [ ] 3.1.3 Update `_input()` to handle touch/click on all 4 buttons (not just Start)

### Phase 3.2 — Options Panel

- [ ] 3.2.1 Create `scenes/ui/options_panel.tscn`: CanvasLayer(11), DimBackground, Panel(9-slice wood), 3× HSlider (Music/SFX/Ambience), CheckButton (fullscreen), CloseButton
- [ ] 3.2.2 Create `scenes/ui/options_panel.gd`: load/save `user://settings.cfg`, call `audio_manager.set_bus_volume()` on value_changed
- [ ] 3.2.3 Persist settings: write on change, read on _ready()

### Phase 3.3 — Credits Panel

- [ ] 3.3.1 Create `scenes/ui/credits_panel.tscn`: CanvasLayer(11), Panel(9-slice), ScrollContainer, RichTextLabel (attribution), BackButton
- [ ] 3.3.2 Create `scenes/ui/credits_panel.gd`: load text from ATTRIBUTION.md; BackButton→hide()

### Phase 3.4 — Pause Overlay

- [ ] 3.4.1 Create `scenes/ui/pause_overlay.tscn`: CanvasLayer(12), process_mode=ALWAYS, DimBackground, Panel, Resume/Options/MainMenu buttons
- [ ] 3.4.2 Create `scenes/ui/pause_overlay.gd`: Resume→emit signal, Options→modal stack, MainMenu→game_manager.return_to_menu()
- [ ] 3.4.3 Update `game_manager.gd._unhandled_input()`: show/hide pause_overlay on ui_cancel toggle

### Phase 3.5 — Game Over Screen

- [ ] 3.5.1 Create `scenes/ui/game_over_screen.tscn`: CanvasLayer(12), process_mode=ALWAYS, Panel, "Reintentar"/"Menú" buttons
- [ ] 3.5.2 Create `scenes/ui/game_over_screen.gd`: Retry→respawn at checkpoint; Menu→return_to_menu()
- [ ] 3.5.3 Update `game_manager.gd`: add `show_game_over()` method; trigger after 3 deaths at same checkpoint

### Phase 3.6 — Integration

- [ ] 3.6.1 Add PauseOverlay, GameOverScreen, OptionsPanel, CreditsPanel as children in `scenes/main/main.tscn`
- [ ] 3.6.2 Move CircleShape2D from `touch_controls.gd` code → `touch_controls.tscn` sub_resources (ADR-007)
- [ ] 3.6.3 Add pause button (top-right) to `hud.tscn`; wire to game_manager pause toggle

**Verify**: All 4 menu screens reachable; pause toggles on Esc; game-over appears on 3rd death; options persist across runs.

---

## PR 4: Cutscenes + Level Refactor (~450 lines) ⚠️ size:exception

Branch: `feature/viking-remodel-cutscenes` (base: PR 3)

### Phase 4.1 — Cutscene Extensions

- [ ] 4.1.1 Create `scenes/ui/portrait_panel.tscn`: TextureRect (128x128) + Label (speaker name)
- [ ] 4.1.2 Add PortraitPanel + BackgroundLayer nodes to `cutscene_manager.tscn`
- [ ] 4.1.3 Update `cutscene_manager.gd._show_line()`: read `portrait`/`background` keys via dict.get(); show/hide portrait_panel; cross-fade background
- [ ] 4.1.4 Add `audio_manager.play_ambience()` call in cutscene start (per-cutscene ambience mapping)

### Phase 4.2 — New Cutscene Dialogue

- [ ] 4.2.1 Add `cinders_intro()` to `narrative_db.gd` (4 lines, portrait=einar, bg=cinders_village)
- [ ] 4.2.2 Add `warpath_intro()` to `narrative_db.gd` (4 lines, bg=snowy_mountains)
- [ ] 4.2.3 Add `england_intro()` to `narrative_db.gd` (3 lines, bg=english_coast, portrait=english_soldier)

### Phase 4.3 — LevelBase

- [ ] 4.3.1 Create `scenes/levels/level_base.gd`: class_name LevelBase, extends Node2D; @onready player/checkpoint/end_trigger; @export level_name, next_level_path, checkpoint_unlocks_fury, checkpoint_upgrades_hp
- [ ] 4.3.2 Implement `_ready()`: wire signals, set initial checkpoint, show level name on HUD
- [ ] 4.3.3 Implement `_on_checkpoint_entered()`: update checkpoint, heal, show HUD banner, handle fury unlock / HP upgrade
- [ ] 4.3.4 Implement `_on_end_trigger_entered()`: add damage bonus, load next level
- [ ] 4.3.5 Create `scenes/levels/level_base.tscn`: Player, Checkpoint, EndTrigger template nodes

### Phase 4.4 — Level Refactoring (7 levels)

- [ ] 4.4.1 Refactor `level_01.gd`: extends LevelBase; set level_name="Farm", next_level_path=L02, checkpoint_unlocks_fury=true; keep IntroTrigger override (~18 lines)
- [ ] 4.4.2 Refactor `level_02.gd`: extends LevelBase; add StoryTrigger for exile_forest cutscene (~16 lines)
- [ ] 4.4.3 Refactor `level_03.gd`: extends LevelBase; add StoryTrigger for **new** cinders_intro cutscene + ambience (~14 lines)
- [ ] 4.4.4 Refactor `level_04.gd`: extends LevelBase; add StoryTrigger for **new** warpath_intro; checkpoint_upgrades_hp=true (~15 lines)
- [ ] 4.4.5 Refactor `level_05.gd`: extends LevelBase; keep boss spawn + before_halvard trigger; checkpoint_upgrades_hp=true (~22 lines)
- [ ] 4.4.6 Refactor `level_06.gd`: extends LevelBase; add StoryTrigger for **new** england_intro; checkpoint_upgrades_hp=true (~14 lines)
- [ ] 4.4.7 Refactor `level_07.gd`: extends LevelBase; override end_trigger (require boss dead); final_boss_intro/defeat triggers; checkpoint_upgrades_hp=true (~26 lines)
- [ ] 4.4.8 Update all 7 `level_*.tscn`: inherit from level_base.tscn where possible; keep per-level unique nodes (platforms, soldiers, boss, triggers)

**Verify**: L3/L4/L6 cutscenes play with portraits+backgrounds+ambience; all 7 levels complete in sequence; APK ~28 MB.
