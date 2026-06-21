# Tasks: Las Cenizas del Oso

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~2500–3500 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (MVP) → PR 2 (Full game) → PR 3 (Polish) |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes — user chose stacked-to-main
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | MVP vertical slice: player + soldier + level_01 + touch + HUD | PR 1 | base=main; all core mechanics playable start-to-finish |
| 2 | Full game: levels 02-07, boss, cutscenes, progression | PR 2 | depends on PR 1; base=main |
| 3 | Polish: Docker export, Android preset, performance | PR 3 | depends on PR 2; base=main |

## Phase 1: MVP Foundation ✅

- [x] 1.1 Create `project.godot` with app config, screen size, Input Map actions (move_left/right, jump, attack_light/heavy, dash, fury)
- [x] 1.2 Create `autoload/game_state.gd` — singleton holding current_level, HP, max_hp, base_damage, fury_cooldown, last_checkpoint
- [x] 1.3 Create `autoload/audio_manager.gd` — audio stub singleton with empty play() methods
- [x] 1.4 Create `assets/sprites/generate_placeholders.gd` — tool script for colored placeholder sprites

## Phase 2: Player System ✅

- [x] 2.1 Create `scenes/player/player.tscn` — CharacterBody2D with CollisionShape2D, AnimatedSprite2D, AttackArea2D, Camera2D
- [x] 2.2 Implement `player.gd` — flat enum (IDLE/RUN/JUMP/ATTACK/DASH/HURT/DEAD), _physics_process dispatch, movement with acceleration, variable-height jump
- [x] 2.3 Add light attack (0.3s cd, 0.15s hitbox, 1 dmg, half move) and heavy attack (0.8s cd, 0.3s hitbox, 2 dmg, knockback, locked move)
- [x] 2.4 Add dash (150px/0.3s, invulnerable, 1s cd) and hurt/dead states with invulnerability flicker (1s)

## Phase 3: Enemies ✅

- [x] 3.1 Create `scenes/enemies/soldier.tscn` + `soldier.gd` — CharacterBody2D, timer-based AI (idle→chase→attack), 3 HP, knockback on hit
- [x] 3.2 Create `scenes/enemies/boss.tscn` + `boss.gd` — phase-based AI (3 phases @66%/33% HP), fast/heavy/enrage attack patterns, 15 HP
- [x] 3.3 Wire health-damage system: Area2D hit detection, HP reduction, knockback direction, death queue_free

## Phase 4: Levels (all 7 levels) ✅

- [x] 4.1 Create `scenes/levels/level_01.tscn` — Farm theme, StaticBody2D terrain, player spawn, 2 soldiers, checkpoint, end trigger
- [x] 4.2 Create `scenes/levels/level_02.tscn` — Burned forest, 4 soldiers, exile cutscene
- [x] 4.3 Create `scenes/levels/level_03.tscn` — Ruined village, 5 soldiers
- [x] 4.4 Create `scenes/levels/level_04.tscn` — Snowy mountains + fort, 6 soldiers, max_hp upgrade
- [x] 4.5 Create `scenes/levels/level_05.tscn` — Jarl's hall arena, Jarl Halvard boss, pre-boss cutscene
- [x] 4.6 Create `scenes/levels/level_06.tscn` — English castle siege, 8 soldiers
- [x] 4.7 Create `scenes/levels/level_07.tscn` — Ash battlefield, Final Boss (son), intro + ending cutscene
- [x] 4.8 Checkpoint Area2Ds per level: save position, restore HP, max_hp+1 on story checkpoints

## Phase 5: UI & Controls ✅

- [x] 5.1 Create `scenes/ui/virtual_joystick.tscn` + `.gd` — left-side d-pad buttons writing to Input Actions
- [x] 5.2 Create `scenes/ui/touch_controls.tscn` + `.gd` — right-side jump/attack/dash buttons, semi-transparent, screen-edge layout
- [x] 5.3 Create `scenes/ui/hud.tscn` + `hud.gd` — health bar (top-left), fury cooldown indicator (top-right), level name banner (top-center, 3s fade)
- [x] 5.4 Create `scenes/ui/main_menu.tscn` + `.gd` — title screen with Start button

## Phase 6: Cutscene & Progression ✅

- [x] 6.1 Create `scenes/cutscene/cutscene_manager.tscn` + `.gd` — CanvasLayer text overlay, autoload, input block/resume
- [x] 6.2 Add cutscene trigger Area2Ds to levels 01, 02, 05, 07 with 15+ dialogue lines from narrative_db.gd
- [x] 6.3 Implement Furia del Oso in `player.gd` + `game_state.gd` — 5s duration, +50% damage, red glow, 30s cooldown
- [x] 6.4 Add stat scaling: damage += 0.5 per level in `game_state.gd`, max_hp+1 upgrade at story checkpoints

## Phase 7: Integration & Polish ✅

- [x] 7.1 Create `main.tscn` + `main.gd` — root node with fade transitions, level load via load_level(), pause/resume
- [x] 7.2 Create `Dockerfile` — robpc/godot-headless:4.3-android, JDK 17, Android AAB/APK export
- [x] 7.3 Create `export_presets.cfg` — Android export preset with landscape orientation, Gradle build
- [x] 7.4 Performance: VisibleOnScreenNotifier2D on all enemies (disable when off-screen), AI tick rate 0.3s (soldier) / 0.5s (boss), deferred collision disabling on death
- [x] 7.5 Edge-case: death-respawn loop guard (3 deaths at same checkpoint → respawn at level start), death plane (Y>1200), cutscene input delay (0.3s), checkpoint idempotent saves
