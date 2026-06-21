# Proposal: Las Cenizas del Oso

## Intent

Build a complete 2D narrative action-platformer for Android using Godot 4 (GDScript). The player controls Einar, a Viking farmer who becomes the warrior "El Oso de Ceniza" after his village is destroyed. The story ends in inevitable tragedy across 7 linear levels.

## Scope

### In Scope
- Player controller with 6 states and 5 mechanics (move, jump, light/heavy attack, dash)
- Enemy Soldier with chase/attack AI
- Boss enemy with phase-based combat
- 7 linear levels with checkpoints
- Touch controls for Android
- Cutscene system (text, camera, input block)
- Progression system (Furia del Oso ability, stat scaling)
- HUD with health bar and ability display
- Docker-based Android export pipeline

### Out of Scope
- Real pixel art assets (colored-rectangle placeholders used)
- Sound effects / music
- Multiplayer or online features
- iOS export
- Level editor or non-linear levels
- Inventory system
- Save/load game state

## Capabilities

### New Capabilities
- `player-system`: CharacterBody2D with movement, combat, animation states (idle/run/jump/attack/hurt/dead)
- `enemy-system`: Soldier AI (idle/chase/attack), Boss with phase-based patterns
- `health-damage-system`: HP, knockback, invulnerability frames, hit detection via Area2D
- `touch-controls`: Virtual buttons and joystick for Android touch input
- `level-system`: TileMapLayer-based linear side-scrolling levels with manual enemy placement and checkpoints
- `cutscene-system`: Text overlay, automatic camera movement, input blocking
- `progression-system`: Furia del Oso (temp damage boost + invulnerability + cooldown), stat scaling per level
- `hud-system`: Health bar, Furia del Oso cooldown, level indicator, checkpoint feedback

### Modified Capabilities
None (greenfield project).

## Approach

Three-phase delivery:

**Phase 1 — MVP**: Player with movement + jump + attack + damage + one enemy + one level + touch controls. This is the playable vertical slice.

**Phase 2 — Full Game**: All 7 levels, boss encounters, cutscene system, progression (Furia del Oso), full enemy roster.

**Phase 3 — Polish**: Docker Android export pipeline, performance optimization, placeholder-to-real-asset bridge, edge-case hardening.

Architecture: Feature-grouped scenes (not type-segregated). AnimatedSprite2D for state-based animation. Custom VirtualJoystick Control node for touch. TileMapLayer for level geometry. Flat state enum in player.gd initially, refactor only if complexity demands it.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `project.godot` | New | Godot 4 project definition |
| `export_presets.cfg` | New | Android export configuration |
| `scenes/player/` | New | Player scene and script |
| `scenes/enemies/` | New | Enemy scenes and AI scripts |
| `scenes/levels/` | New | 7 level scenes |
| `scenes/ui/` | New | HUD, touch controls, menus |
| `scenes/cutscene/` | New | Cutscene manager |
| `autoload/` | New | Global game state, audio stubs |
| `assets/sprites/` | New | Placeholder colored-rect sprites |
| `Dockerfile` | New | Android export pipeline |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| No Godot binary locally | High | Docker-based workflow from day 1 |
| Touch controls need device testing | Medium | Emulate touch from mouse in editor |
| Placeholder sprites mislead collision tuning | Medium | Use consistent 16x16 grid for tiles, 32x32 for characters |
| 7 levels = large scope for single contributor | High | Phased delivery; MVP first, expand iteratively |
| JDK/NDK version mismatch in Docker | Medium | Pin exact versions in Dockerfile |

## Rollback Plan

Git revert on `openspec/changes/las-cenizas-del-oso/` plus any game files created. Each phase is a standalone commit that can be reverted independently.

## Dependencies

- Godot 4 (any 4.x stable — develop with plain GDScript)
- Docker with `robpc/godot-headless:4.3-android` (or compatible) for Android export
- JDK 17 for Android Gradle build in Docker

## Success Criteria

- [ ] Player moves, jumps, attacks, dashes with touch controls
- [ ] Enemy chases player and takes damage
- [ ] At least Level_01_Farm playable start-to-finish
- [ ] Touch controls work without keyboard
- [ ] Docker build produces an APK/AAB
- [ ] Cutscene system displays text and blocks input
- [ ] Furia del Oso ability activates with cooldown
- [ ] All 7 levels have geometry and enemies
