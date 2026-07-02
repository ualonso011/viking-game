# Design: Viking Game Remodel

## Technical Approach

Swap the visual + audio layers of the existing mechanically-complete Godot 4 game without touching gameplay logic. Concretely: (1) replace every `null` texture with illustrated PNGs generated procedurally + bundled OFL font + 9-slice panel textures, (2) rewrite the `audio_manager.gd` autoload with real bus-backed playback, (3) add the three missing cutscenes (L3, L4, L6) using an extended dialogue format with optional portrait/background, (4) introduce a `LevelBase` scene/script that absorbs the 7-level copy-paste, (5) complete the UI surfaces (pause overlay, game-over, options, credits) as siblings of the existing `main_menu.tscn`, (6) validate the Android export pipeline still ships. No new autoloads, no class_name declarations, no `window/stretch/*` in `project.godot` (memory #55: headless export breaks).

The change touches ~35 files across `assets/`, `autoload/`, `scenes/ui/`, `scenes/cutscene/`, `scenes/levels/`. Estimated delta: ~1100 lines (visual layer only; logic untouched). That exceeds the 400-line review budget; this change MUST be split into chained PRs — see `Migration Strategy` below.

---

## Architecture Decisions

### ADR-001: Bundled OFL font (Cinzel primary, Uncial Antiqua fallback)

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Cinzel only (OFL, ~250 KB TTF) | Roman capitals, classy, fits "noble Viking" tone | **Primary** |
| Uncial Antiqua (OFL, ~150 KB TTF) | Uncial script, more "runic" feel | **Secondary fallback** |
| Godot default bitmap | Sterile, no identity | Reject |
| Custom paid font | License risk | Reject |

**Rationale**: Both fonts are SIL OFL 1.1 (commercial-safe, attribution required). Cinzel renders Latin text more legibly at 16-24px; Uncial Antiqua is reserved for the title screen only. Bundle both under `assets/fonts/` and register via `viking_theme.tres` (see ADR-003).

### ADR-002: Procedural sprite generation pipeline (NOT asset downloads)

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Extend `generate_placeholders.gd` with more shapes/tints | Deterministic, no license risk, ~0 KB added | **Choose** |
| Hand-drawn pixel art | Higher quality, needs artist | Reject (out of scope) |
| AI image generation | License ambiguity, style drift | Reject |
| OpenGameArt CC-BY pixel art | License-clean, but inconsistent style | Reject for v1 |

**Rationale**: Player/soldier/boss are stylized 32-48px rectangles with palette tints. Extending the existing `@tool` script keeps the asset pipeline reproducible in CI (Docker can regenerate). Style coherence is enforced by a single 4-color palette; real pixel art swap is a future change.

### ADR-003: `viking_theme.tres` is the single source of UI truth

| Element | Type | Source |
|---------|------|--------|
| `default_font` | `FontFile` (Cinzel) | `res://assets/fonts/Cinzel-Regular.ttf` |
| `default_font_size` | `int` 18 | hand-tuned for 1920x1080 base |
| Button styleboxes (normal/hover/pressed/disabled) | `StyleBoxTexture` (9-slice from `panel_wood.tres`) | `res://assets/themes/panel_wood.tres` |
| Panel stylebox | `StyleBoxTexture` (9-slice) | same |
| Label font_color | `Color(0.94, 0.91, 0.85, 1.0)` | bone white |
| Label outline | enabled, `Color(0, 0, 0, 0.8)`, size 2 | improves legibility on busy backgrounds |

**Rationale**: Every UI scene sets `theme = preload("res://assets/themes/viking_theme.tres")` in `_ready()`. Removes per-scene `add_theme_color_override()` boilerplate. Replaces the current "set colors in code" pattern (see `main_menu.gd:21-22`).

### ADR-004: AudioManager = bus-backed Node, NOT raw `AudioStreamPlayer` soup

| Concern | Current | Target |
|---------|---------|--------|
| API surface | 4 `pass` methods | 6 typed methods: `play_music(track, loop=true)`, `play_sfx(name)`, `play_ambience(track)`, `stop_music(fade_ms)`, `set_bus_volume(bus, db)`, `get_bus_volume(bus)` |
| Music playback | none | dedicated `AudioStreamPlayer` per bus, cross-fade on `play_music` |
| SFX | none | pool of 8 `AudioStreamPlayer` nodes round-robin (cheap, avoids polyphony clipping) |
| Ambience | none | dedicated looping player on `Ambience` bus, mixable with music |
| Volume control | none | `AudioServer.set_bus_volume_db()` with 0.0..1.0 linear → dB conversion |

**Rationale**: Three buses (`Music`, `SFX`, `Ambience`) match the `audio_manager` API and let the future Options screen adjust each independently. SFX pool avoids per-shot `AudioStreamPlayer.new()` allocations during combat (mobile GC concern).

### ADR-005: Cutscene lines keep flat dict, gain optional `portrait` + `background` keys

```gdscript
# Old:
{"speaker": "Einar", "text": "..."}

# New (backward compatible):
{"speaker": "Einar", "text": "...", "portrait": "einar", "background": "farm_burning"}
# Both keys optional; missing key = no visual change (text-only line, like L1/L2/L5/L7 today)
```

**Rationale**: Extending the existing dict is zero-cost for old scenes and lets the 3 new cutscenes (L3, L4, L6) opt into portraits. `cutscene_manager.gd` reads keys defensively (`line.get("portrait", "")`). No dialogue refactor needed.

### ADR-006: `LevelBase` scene/script absorbs checkpoint + end-trigger + level-name boilerplate

```gdscript
# scenes/levels/level_base.gd  (new)
class_name LevelBase  # safe here (not autoload, no Android export bug)
extends Node2D

@onready var player: Node = $Player
@onready var checkpoint: Area2D = $Checkpoint
@onready var end_trigger: Area2D = $EndTrigger
@export var level_name: String = "Level"
@export var next_level_path: String = ""
@export var checkpoint_unlocks_fury: bool = false
@export var checkpoint_upgrades_hp: bool = false

func _ready() -> void:
    # wire signals, set initial state
    var hud = get_node_or_null("/root/Main/HUD")
    if hud and hud.has_method("show_level_name"):
        hud.show_level_name(level_name, 3.0)
    if player:
        game_state.last_checkpoint = player.global_position
        game_state.checkpoint_level = scene_file_path

func _on_checkpoint_entered(body: Node) -> void:
    if body.is_in_group("player"):
        game_state.last_checkpoint = checkpoint.global_position
        game_state.current_hp = game_state.max_hp
        var hud = get_node_or_null("/root/Main/HUD")
        if hud: hud.show_checkpoint()
        if checkpoint_unlocks_fury and not game_state.fury_unlocked:
            game_state.fury_unlocked = true  # setter emits signal
        if checkpoint_upgrades_hp:
            game_state.upgrade_max_hp(1)

func _on_end_trigger_entered(body: Node) -> void:
    if body.is_in_group("player"):
        game_state.add_level_damage_bonus()
        if next_level_path != "":
            game_manager.load_level(next_level_path)
```

Each per-level `.gd` becomes 5-10 lines: a cutscene trigger (if any), plus per-level tuning (boss spawn, story_trigger, etc.). Estimated reduction: 7 × ~50 lines → 7 × ~15 lines = ~245 lines saved across the change.

**Rationale**: `class_name` on a non-autoload script is safe (the Android export bug from ADR-005 of the prior change only affects autoloads). Subclasses use `@onready` overrides for the story_trigger / boss nodes that only L1, L2, L5, L7 have.

### ADR-007: Touch shapes move from `.gd` assignment to `.tscn` `[sub_resource]`

`touch_controls.gd _ready()` currently constructs `CircleShape2D` in code. Per the prior change's ADR-005, this was acceptable but a scene-editor smell. Move both `CircleShape2D` resources (`right_shape` r=80, `left_shape` r=60) into `touch_controls.tscn` as `[sub_resource]` and reference them by name. Reduces `touch_controls.gd` from 49 lines to ~25.

### ADR-008: No `class_name` on autoloads (carryover from game-modernization)

Confirmed. `game_manager.gd`, `game_state.gd`, `audio_manager.gd`, `narrative_db.gd` stay as plain scripts accessed by their registered name. `LevelBase` (ADR-006) is the only new `class_name` and it is not an autoload.

---

## Directory Structure (target)

```
assets/
├── fonts/
│   ├── Cinzel-Regular.ttf          (OFL, ~250 KB)
│   ├── Cinzel-Bold.ttf              (OFL, ~250 KB)
│   ├── UncialAntiqua-Regular.ttf   (OFL, ~150 KB)
│   └── FONT_LICENSE.txt             (OFL attribution)
├── audio/
│   ├── music/
│   │   ├── menu_theme.ogg           (CC0, ~600 KB)
│   │   ├── farm_ambient.ogg
│   │   ├── halvard_boss.ogg
│   │   └── ash_battlefield.ogg
│   ├── sfx/
│   │   ├── sword_light.ogg
│   │   ├── sword_heavy.ogg
│   │   ├── hit_player.ogg
│   │   ├── hit_enemy.ogg
│   │   ├── ui_click.ogg
│   │   ├── ui_hover.ogg
│   │   ├── checkpoint.ogg
│   │   └── death.ogg
│   ├── ambience/
│   │   ├── wind.ogg
│   │   ├── fire_crackle.ogg
│   │   └── rain.ogg
│   └── ATTRIBUTION.md              (CC-BY credits)
├── sprites/
│   ├── player/
│   │   ├── player_idle.png
│   │   ├── player_run.png          (4-frame horizontal strip)
│   │   ├── player_attack_light.png
│   │   ├── player_attack_heavy.png
│   │   ├── player_jump.png
│   │   ├── player_dash.png
│   │   ├── player_hurt.png
│   │   └── player_dead.png
│   ├── enemies/
│   │   ├── soldier_idle.png
│   │   ├── soldier_run.png
│   │   ├── soldier_attack.png
│   │   ├── soldier_hurt.png
│   │   ├── soldier_dead.png
│   │   ├── boss_halvard_idle.png
│   │   ├── boss_halvard_enraged.png
│   │   ├── boss_final_idle.png
│   │   └── boss_final_enraged.png
│   ├── ui/
│   │   ├── health_bar_bg.png
│   │   ├── health_bar_fill.png
│   │   ├── fury_icon.png
│   │   └── checkpoint_flag.png
│   ├── portraits/
│   │   ├── narrator.png            (silhouette placeholder)
│   │   ├── einar.png
│   │   ├── halvard.png
│   │   ├── young_warrior.png
│   │   └── english_soldier.png
│   ├── backgrounds/
│   │   ├── farm_burning.png
│   │   ├── cinders_village.png
│   │   ├── snowy_mountains.png
│   │   └── english_coast.png
│   ├── platform_wood.png
│   ├── panel_wood.png              (9-slice source: 32px frame, 64x64 source)
│   ├── panel_stone.png             (9-slice source)
│   ├── icon.png                    (192x192 master)
│   └── generate_assets.gd          (extends existing @tool script)
├── themes/
│   ├── viking_theme.tres           (Theme — fonts, colors, styleboxes)
│   ├── panel_wood.tres             (StyleBoxTexture — 9-slice)
│   └── panel_stone.tres            (StyleBoxTexture — 9-slice)
└── licenses/                       (every OFL/CC0/CC-BY text + hashes)

scenes/
├── ui/
│   ├── main_menu.tscn              (extended: Start + Options + Credits + Exit)
│   ├── options_panel.tscn          (new — sliders for music/sfx/ambience)
│   ├── credits_panel.tscn          (new — scrollable RichTextLabel)
│   ├── pause_overlay.tscn          (new — Resume / Options / Main Menu)
│   ├── game_over_screen.tscn       (new — Retry / Main Menu)
│   ├── hud.tscn                    (theme-applied, same nodes)
│   ├── touch_controls.tscn         (shapes as sub_resource, theme applied)
│   └── portrait_panel.tscn         (new — TextureRect + Label; shown during cutscene)
├── cutscene/
│   ├── cutscene_manager.tscn       (extended with PortraitPanel + BackgroundLayer)
│   └── cutscene_manager.gd         (dict.get() defensive reads)
├── levels/
│   ├── level_base.tscn             (new — Player, Checkpoint, EndTrigger template)
│   ├── level_base.gd               (new — LevelBase class)
│   ├── level_01.tscn/.gd           (extends LevelBase, adds IntroTrigger)
│   ├── level_02.tscn/.gd           (extends LevelBase, adds StoryTrigger)
│   ├── level_03.tscn/.gd           (extends LevelBase, adds StoryTrigger — NEW CUTSCENE)
│   ├── level_04.tscn/.gd           (extends LevelBase, adds StoryTrigger — NEW CUTSCENE)
│   ├── level_05.tscn/.gd           (extends LevelBase, adds StoryTrigger + Boss)
│   ├── level_06.tscn/.gd           (extends LevelBase, adds StoryTrigger — NEW CUTSCENE)
│   └── level_07.tscn/.gd           (extends LevelBase, adds StoryTrigger + Boss)
```

---

## Data Flow

### Main Menu Flow (extended)

```
main_menu.tscn  (CanvasLayer layer=10)
└── Background (TextureRect, farm_burning.png parallax)
└── VBoxContainer
    ├── TitleLabel       (Uncial Antiqua 96pt, bone white)
    ├── SubtitleLabel    (Cinzel 24pt, ember)
    ├── StartButton      (Cinzel 18pt) ──pressed──→ game_manager.start_game()
    ├── OptionsButton    ──pressed──→ options_panel.show()
    ├── CreditsButton    ──pressed──→ credits_panel.show()
    └── ExitButton       ──pressed──→ get_tree().quit()

options_panel.tscn (sibling, layer=11)
├── DimBackground (ColorRect, alpha 0.6)
├── Panel (StyleBoxTexture 9-slice panel_wood)
│   ├── HSlider Music    (0.0-1.0) ──value_changed──→ audio_manager.set_bus_volume("Music", v)
│   ├── HSlider SFX
│   ├── HSlider Ambience
│   ├── CheckButton Fullscreen
│   └── CloseButton    ──pressed──→ hide()
└── Save values to user://settings.cfg

credits_panel.tscn: same shape, RichTextLabel with attribution text from assets/audio/ATTRIBUTION.md
```

### Pause Flow (NEW)

```
game_manager._unhandled_input("ui_cancel")
├─ if state == PLAYING: state = PAUSED; get_tree().paused = true; pause_overlay.show()
└─ if state == PAUSED:  state = PLAYING; get_tree().paused = false; pause_overlay.hide()

pause_overlay.tscn  (CanvasLayer, process_mode=ALWAYS)
├── DimBackground (alpha 0.5)
└── Panel
    ├── ResumeButton    ──pressed──→ emit "resume" ──→ game_manager._unhandled_input cycles state
    ├── OptionsButton   ──pressed──→ options_panel.show() (modal stack)
    └── MainMenuButton  ──pressed──→ game_manager.return_to_menu()
```

### Audio Flow (NEW)

```
audio_manager.gd  (autoload, Node)
├── Bus Layout (configured via project.godot):
│   ├── Master  (default 0 dB)
│   ├── Music   (default -6 dB, controlled by Options)
│   ├── SFX     (default 0 dB)
│   └── Ambience (default -10 dB)
├── MusicPlayer: AudioStreamPlayer (bus=Music)
├── AmbiencePlayer: AudioStreamPlayer (bus=Ambience, loop=true)
└── SFXPool: 8x AudioStreamPlayer (bus=SFX) round-robin

play_music(track_name, loop=true):
    var stream = preload("res://assets/audio/music/{track_name}.ogg")
    if MusicPlayer.playing:
        var old = MusicPlayer
        MusicPlayer = AudioStreamPlayer.new()
        MusicPlayer.bus = "Music"
        old.volume_db = 0
        var t = create_tween().set_parallel(true)
        t.tween_property(old, "volume_db", -40, 0.5)
        t.tween_property(MusicPlayer, "volume_db", 0, 0.5).set_delay(0.5)
        MusicPlayer.stream = stream
        add_child(MusicPlayer)
        MusicPlayer.play()
    else:
        MusicPlayer.stream = stream
        MusicPlayer.play()

play_sfx(name):
    var next = _sfx_pool[_sfx_idx]
    _sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
    next.stream = load("res://assets/audio/sfx/{name}.ogg")
    next.play()

play_ambience(track_name):
    AmbiencePlayer.stream = load(...)
    AmbiencePlayer.play()
```

### Cutscene Trigger Flow (NEW for L3/L4/L6)

```
level_03._ready (extends LevelBase)
└── StoryTrigger (Area2D) at position 1600,720
    body_entered ──→ _on_story_trigger
        └─→ cutscene.play_cutscene(narrative_db.cinders_intro())
              ├─→ tree.paused = true (cutscene already runs PROCESS_MODE_WHEN_PAUSED)
              ├─→ _show_line(0) → displays portrait=einar, background=cinders_village
              ├─→ tap → _show_line(1) ...
              └─→ all lines done → emit cutscene_finished
                    └─→ game_manager.state = PLAYING, tree.paused = false
```

---

## Key Interfaces / Contracts

### `audio_manager.gd` public API

```gdscript
extends Node
## AudioManager: bus-backed music + SFX + ambience. Singleton via autoload.

signal music_finished
signal bus_volume_changed(bus: StringName, linear: float)

func play_music(track_name: StringName, loop: bool = true) -> void
func stop_music(fade_ms: int = 500) -> void
func play_sfx(sfx_name: StringName) -> void
func play_ambience(track_name: StringName) -> void
func stop_ambience(fade_ms: int = 500) -> void
func set_bus_volume(bus: StringName, linear: float) -> void  # 0.0..1.0
func get_bus_volume(bus: StringName) -> float
```

### `narrative_db.gd` extended lines (L3, L4, L6)

```gdscript
# Level 03 - Cinders: entering the ruined village
func cinders_intro() -> Array[Dictionary]:
    return [
        {"speaker": "Narrator", "text": "Lo que fue granja es ahora ceniza.", "background": "cinders_village"},
        {"speaker": "Einar", "text": "Restos de hogares. Los de Halvard pasaron por aquí como langostas.", "portrait": "einar"},
        {"speaker": "Narrator", "text": "Cada paso que da, el oso que lleva dentro crece un poco más."},
        {"speaker": "Einar", "text": "El odio es combustible. No me quedará nada cuando esto termine."},
    ]

# Level 04 - Warpath: snowy mountains
func warpath_intro() -> Array[Dictionary]:
    return [
        {"speaker": "Narrator", "text": "Las montañas de nieve reciben a Einar con un silencio blanco.", "background": "snowy_mountains"},
        {"speaker": "Einar", "text": "El frío me recuerda a casa. Antes del fuego."},
        {"speaker": "Narrator", "text": "Una fortaleza se asoma entre la niebla. La morada del Jarl."},
        {"speaker": "Einar", "text": "Halvard. Por fin."},
    ]

# Level 06 - England: arriving on hostile shores
func england_intro() -> Array[Dictionary]:
    return [
        {"speaker": "Narrator", "text": "Inglaterra. La tierra que Halvard sirve.", "background": "english_coast"},
        {"speaker": "Einar", "text": "Si mi hijo está aquí, lo encontraré. Aunque tenga que cruzar este reino entero."},
        {"speaker": "English Soldier", "text": "¡Ahí! ¡Un vikingo! ¡A las armas!", "portrait": "english_soldier"},
    ]
```

### `cutscene_manager.gd` extended (defensive)

```gdscript
func _show_line() -> void:
    if current_line >= dialogue_lines.size():
        _end_cutscene(); return
    var line: Dictionary = dialogue_lines[current_line]
    text_label.text = "[%s]\n%s" % [line.get("speaker", ""), line.get("text", "")]
    var portrait_key: String = line.get("portrait", "")
    if portrait_key != "":
        portrait_panel.texture = load("res://assets/sprites/portraits/%s.png" % portrait_key)
        portrait_panel.show()
    else:
        portrait_panel.hide()
    var bg_key: String = line.get("background", "")
    if bg_key != "":
        background_layer.texture = load("res://assets/sprites/backgrounds/%s.png" % bg_key)
    # 0.3s input delay (existing behavior preserved)
```

### `LevelBase` contract (from ADR-006)

```gdscript
# Subclasses MUST set @export vars:
#   level_name (String)         — banner text on HUD
#   next_level_path (String)    — res:// path; empty = final level
# Subclasses MAY set:
#   checkpoint_unlocks_fury (bool) — L1 only
#   checkpoint_upgrades_hp (bool)  — L4, L6, L7
# Subclasses MAY override:
#   _on_story_trigger(body)  — L1, L2, L3, L4, L5, L6, L7
#   _on_end_trigger_entered(body) — L7 (prevents end until boss dead)
```

---

## Level Script Refactoring — Concrete Mapping

| Level | Current lines | Target lines | New behavior |
|-------|---------------|--------------|--------------|
| 01 | 52 | 18 (extends LevelBase) + IntroTrigger override | fury unlock moves from `_on_checkpoint_entered` to `checkpoint_unlocks_fury=true` export |
| 02 | 49 | 16 + exile_forest trigger | no checkpoint upgrade (current behavior) |
| 03 | 39 | 14 + **NEW** cinders_intro trigger | first time this level has a cutscene |
| 04 | 41 | 15 + **NEW** warpath_intro trigger | first time, plus `checkpoint_upgrades_hp=true` |
| 05 | 59 | 22 + before_halvard trigger + boss spawn | `checkpoint_upgrades_hp=true` |
| 06 | 40 | 14 + **NEW** england_intro trigger | first time, plus `checkpoint_upgrades_hp=true` |
| 07 | 69 | 26 + final_boss_intro + final_boss_defeat triggers | `checkpoint_upgrades_hp=true`, override end-trigger to require boss dead |
| **Total** | **349** | **~125** | **-224 lines net** |

The 7 `.tscn` files also become uniform: same Player/Checkpoint/EndTrigger nodes (inherited from `level_base.tscn`), plus per-level ColorRect platforms, instanced soldiers, optional Boss, optional StoryTrigger/IntroTrigger.

---

## Audio Bus Layout (project.godot additions)

```ini
[audio]
buses/master_bus/name="Master"
buses/music_bus/name="Music"
buses/sfx_bus/name="SFX"
buses/ambience_bus/name="Ambience"
# Default volumes set in audio_manager.gd._ready() based on user://settings.cfg
```

All `.ogg` files in `assets/audio/` are preloaded via the `audio_manager` API; **no** `preload()` in scenes (keeps memory predictable, single source of truth for which bus plays what).

---

## Android Export Validation

### Size budget

| Asset class | Current | Target | Compression |
|-------------|---------|--------|-------------|
| Sprites (PNG) | 0 KB | ~600 KB total | Lossy WebP via Godot import, max 256x256 |
| Fonts (TTF) | 0 | ~650 KB (3 fonts) | TTF as-is (Godot 4 supports subsetting; embed only Latin) |
| Audio (OGG) | 0 | ~3.5 MB (music+sfx+ambience) | OGG Vorbis q=0.4, mono, 22050 Hz |
| Existing assets | ~5 MB | ~5 MB (unchanged) | APK 23 MB baseline + ~5 MB new = **~28 MB APK** |
| **APK total** | **23 MB** | **~28 MB** | Within Android 50 MB install limit |

### Risk mitigations

1. **Stretch mode**: keep `get_window().content_scale_*` in `game_manager.gd._ready()` (memory #55: never put `window/stretch/*` in `project.godot`).
2. **CI verification**: GitHub Actions workflow (`.github/workflows/android-export.yml`) is unchanged; add a step that runs `godot --headless --validate-project` before the export step.
3. **New font import warnings**: Godot 4.3 logs "no outlines" warnings for TTF without `antialiasing` set. Add `font_data/antialiasing = 1` to each font import in `assets/fonts/`.
4. **Texture compression**: `textures/vram_compression/import_etc2_astc=true` is already in `project.godot`. New PNG sprites inherit ETC2/ASTC compression on Android export.
5. **Audio format**: OGG Vorbis is Android-native. No transcoding needed.

### Validation steps (verify phase)

1. `./Godot_v4.3-stable_linux.x86_64 --headless --validate-project` → 0 errors
2. `docker build` (Dockerfile unchanged) → APK builds, ~28 MB
3. Install on Android device → main menu renders with Cinzel/Uncial, music plays, all 7 levels playable
4. Touch 7 existing buttons + 3 new menu buttons → all trigger correct actions
5. Pause menu shows on `ui_cancel`; resume returns to gameplay
6. Options sliders adjust music/SFX/ambience bus volume live

---

## File Changes Summary

| File | Action | Δ lines | Notes |
|------|--------|---------|-------|
| `autoload/audio_manager.gd` | Rewrite | +90 | Bus API, SFX pool, cross-fade |
| `autoload/narrative_db.gd` | Extend | +25 | cinders_intro, warpath_intro, england_intro |
| `assets/fonts/*.ttf` | Create (binary) | n/a | 3 OFL fonts |
| `assets/audio/**/*` | Create (binary) | n/a | ~25 OGG files, all CC0/CC-BY |
| `assets/sprites/**/*` | Generate | n/a | via extended `generate_assets.gd` |
| `assets/sprites/generate_assets.gd` | Modify (rename from placeholders) | +50 | More shapes, 9-slice panels, portraits |
| `assets/themes/viking_theme.tres` | Rewrite | +35 | Fonts, stylebox refs, palette |
| `assets/themes/panel_wood.tres` | Create | ~10 | 9-slice StyleBoxTexture |
| `assets/themes/panel_stone.tres` | Create | ~10 | 9-slice StyleBoxTexture |
| `scenes/ui/main_menu.tscn` | Modify | +30 | 3 new buttons, theme applied |
| `scenes/ui/main_menu.gd` | Simplify | -40 | Remove stylebox code (theme does it) |
| `scenes/ui/hud.tscn` | Modify | +5 | theme applied; shape sizes unchanged |
| `scenes/ui/hud.gd` | Modify | +5 | Use theme font sizes |
| `scenes/ui/touch_controls.tscn` | Modify | +15 | shapes as sub_resource |
| `scenes/ui/touch_controls.gd` | Simplify | -25 | Remove shape code |
| `scenes/ui/options_panel.tscn` | Create | ~50 | new scene |
| `scenes/ui/options_panel.gd` | Create | ~40 | new script |
| `scenes/ui/credits_panel.tscn` | Create | ~30 | new scene |
| `scenes/ui/credits_panel.gd` | Create | ~15 | new script |
| `scenes/ui/pause_overlay.tscn` | Create | ~40 | new scene |
| `scenes/ui/pause_overlay.gd` | Create | ~30 | new script |
| `scenes/ui/game_over_screen.tscn` | Create | ~35 | new scene |
| `scenes/ui/game_over_screen.gd` | Create | ~30 | new script |
| `scenes/ui/portrait_panel.tscn` | Create | ~15 | new scene |
| `scenes/cutscene/cutscene_manager.tscn` | Modify | +25 | PortraitPanel + BackgroundLayer nodes |
| `scenes/cutscene/cutscene_manager.gd` | Modify | +20 | dict.get() for portrait/bg, audio cues |
| `scenes/levels/level_base.gd` | Create | ~50 | new LevelBase class |
| `scenes/levels/level_base.tscn` | Create | ~80 | new base scene (Player, Checkpoint, EndTrigger) |
| `scenes/levels/level_01.gd` | Refactor | -34 | extends LevelBase |
| `scenes/levels/level_01.tscn` | Refactor | -20 | inherits base structure |
| `scenes/levels/level_02.gd` | Refactor | -33 | extends LevelBase |
| `scenes/levels/level_03.gd` | Modify | -25 | extends LevelBase, adds cinders_intro |
| `scenes/levels/level_04.gd` | Modify | -26 | extends LevelBase, adds warpath_intro |
| `scenes/levels/level_05.gd` | Modify | -37 | extends LevelBase, boss spawn |
| `scenes/levels/level_06.gd` | Modify | -26 | extends LevelBase, adds england_intro |
| `scenes/levels/level_07.gd` | Refactor | -43 | extends LevelBase, final boss override |
| `autoload/game_manager.gd` | Modify | +15 | `change_state(state)`, `show_game_over()`, audio bus init |
| `scenes/main/main.tscn` | Modify | +5 | Add PauseOverlay, GameOverScreen as siblings |
| `project.godot` | Modify | +5 | Audio bus layout, font import settings |
| `icon.svg` | Replace | n/a | Viking rune "ᚦ" (Thurisaz) on dark, 192px |
| `assets/licenses/*` | Create | n/a | OFL/CC0/CC-BY text files |
| **Total code delta** | | **~+800 / -350 = +450 net** | Within chained PR budget when split |

---

## Migration Strategy — Chained PRs

The 400-line review budget cannot absorb this change. Split into 4 chained PRs, each independently reviewable and reversible:

### PR 1: Asset Pipeline (foundation, ~350 lines)

- `assets/fonts/*` (3 TTF, 0 code)
- `assets/sprites/**` (generated PNGs, 0 code)
- `assets/sprites/generate_assets.gd` (extended @tool script)
- `assets/themes/viking_theme.tres` (theme resource)
- `assets/themes/panel_wood.tres`, `panel_stone.tres` (9-slice styleboxes)
- `icon.svg` (replaced)
- `scenes/player/player.tscn` — assign sprite frames
- `scenes/enemies/soldier.tscn`, `boss.tscn` — assign sprite frames
- `scenes/levels/level_01-07.tscn` — replace ColorRect platforms with 9-slice Sprite2D

**Reviewer focus**: visual coherence, palette consistency. Mechanical changes; low logic risk.
**Verification**: editor screenshot of each level + APK build succeeds.

### PR 2: Audio + Theme (cross-cutting, ~250 lines)

- `autoload/audio_manager.gd` (rewrite)
- `project.godot` audio bus config
- `assets/audio/**` (binary)
- `assets/licenses/*` (attribution docs)
- All `scenes/ui/*.tscn` — apply theme via `theme = preload(...)`
- Remove stylebox code from `main_menu.gd`, `touch_controls.gd` (now redundant)

**Reviewer focus**: audio bus topology, volume math, license correctness.
**Verification**: APK builds, music/SFX/ambience play in dev, options sliders adjust live.

### PR 3: Menu UI + Pause/GameOver/Options/Credits (~400 lines)

- `scenes/ui/main_menu.tscn/.gd` (4 buttons, theme-styled)
- `scenes/ui/options_panel.tscn/.gd` (new)
- `scenes/ui/credits_panel.tscn/.gd` (new)
- `scenes/ui/pause_overlay.tscn/.gd` (new)
- `scenes/ui/game_over_screen.tscn/.gd` (new)
- `autoload/game_manager.gd` — `change_state()`, `show_pause()`, `show_game_over()`, `return_to_menu()` updates
- `scenes/main/main.tscn` — add 4 new CanvasLayer siblings
- `scenes/ui/touch_controls.tscn` — move shapes to sub_resource

**Reviewer focus**: scene tree, signal flow, process_mode for pause overlay.
**Verification**: every menu screen reachable; pause toggles on Esc; game-over appears on death; options persist across runs.

### PR 4: Cutscenes + Level Refactor (~450 lines)

- `scenes/cutscene/cutscene_manager.tscn/.gd` — PortraitPanel + BackgroundLayer
- `scenes/ui/portrait_panel.tscn` (new)
- `autoload/narrative_db.gd` — 3 new cutscene functions (L3, L4, L6)
- `scenes/levels/level_base.tscn/.gd` (new)
- All 7 `level_*.gd` refactored to extend LevelBase
- `level_03`, `level_04`, `level_06` get new StoryTrigger + SceneTreeExport (`next_level_path`)

**Reviewer focus**: dialogue voice consistency, LevelBase contract adherence, cutscene→gameplay handoff.
**Verification**: L3, L4, L6 cutscenes play; all 7 levels still complete in sequence; APK ~28 MB.

**Chained PR protocol** (per `chained-pr` skill):
- PR 1 → `feature/viking-remodel-assets` (base)
- PR 2 → targets `feature/viking-remodel-assets` (after PR 1 merges)
- PR 3 → targets `feature/viking-remodel-audio` (after PR 2 merges)
- PR 4 → targets `feature/viking-remodel-menus` (after PR 3 merges)
- After all merge: a `viking-remodel` integration branch rebase ensures the diff against `main` is the sum of all 4 PRs.

**Rollback**: revert the integration commit. Each PR is independently revertable because asset references are paths, not embedded data. If PR 4 fails review, PRs 1-3 ship the visual/audio layer with the existing 7-level scripts; the game still plays.

---

## Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | OFL font has a missing glyph (e.g., "ñ" in Spanish) | Low | Low | Godot 4.3 falls back to system font; verify in Cinzel-Regular coverage |
| 2 | Audio bus layout breaks existing `_unhandled_input` audio route | Low | Medium | audio_manager is new; existing gameplay never calls it; safe |
| 3 | `LevelBase` refactor breaks L5 or L7 boss flow (subtle) | Medium | High | Apply `LevelBase` to L1-L4 first (no boss), verify; then L5/L7 with manual test |
| 4 | 9-slice panel textures look wrong at non-1.0 scale | Medium | Low | `expand_margin_*` set per panel; test at 1.0x and 2.0x |
| 5 | APK exceeds 30 MB (Play Store limit) | Low | Medium | Subset fonts to Latin only (~150 KB saved); compress OGG to q=0.3 (~500 KB saved) |
| 6 | Options screen persists settings but the file write path differs on Android | Medium | Low | `user://settings.cfg` is Godot's standard Android writable path; verified in game-modernization change |
| 7 | L3/L4/L6 cutscene voice doesn't match existing | Medium | Low | Hand off dialogue to user for review before PR 4 merge; if rejected, ship without those 3 cutscenes (still PR 4 wins on LevelBase refactor) |
| 8 | Chained PR drift — PR 2 retargeted incorrectly | Medium | Low | CI must show each PR's diff is small and scoped; retarget/rebase per `chained-pr` protocol |

---

## Open Questions

- [ ] **Font subsetting scope**: Cinzel supports Latin Extended; do we need Cyrillic (Russian players) or Greek? Default to Latin only to save space; expand if user requests.
- [ ] **Music length per level**: 4 music tracks for 7 levels means 3 levels reuse (L1+L2 share "calm village", L3+L4 share "danger", L5+L6 share "siege", L7 unique). Acceptable?
- [ ] **Game-over trigger**: on death, show game-over AFTER 2s respawn timer, or REPLACE respawn? Spec says "death = 2s respawn with no feedback" — replacing with retry/main-menu choice is the more interesting option, but breaks the softlock guard. Decision: keep auto-respawn at checkpoint, but add game-over screen as a final option after 3 deaths at the same checkpoint (existing death_count_at_checkpoint guard integrates cleanly).
- [ ] **Pause overlay process_mode**: must be `PROCESS_MODE_ALWAYS` so it appears while tree is paused. Confirm in PR 3 review.
- [ ] **HUD theme override**: the existing HUD has hardcoded `theme_override_colors/font_color = Color(1, 1, 1, 1)` in the `.tscn` — these must be removed or the theme won't apply. Trivial fix in PR 2; flagged for reviewer attention.

---

## Next Step

Ready for **sdd-tasks**. Tasks should be structured around the 4 chained PRs, with explicit per-PR verification gates and rollback notes. Estimated tasks: ~60 (15 per PR).
