# Design: Las Cenizas del Oso

## Technical Approach

Godot 4 (GDScript) 2D action-platformer for Android. Feature-grouped scenes, flat state machines, AnimatedSprite2D for animation, TileMapLayer for levels, custom virtual buttons for touch. Placeholder colored-rect sprites. Docker-based Android export.

## Architecture Decisions

### Decision: Character Controller

**Choice**: CharacterBody2D with flat enum state dispatch
**Alternatives**: State node pattern, Behavior Tree
**Rationale**: 6 states fits a flat enum without needing node overhead. Refactor to State pattern only if complexity grows beyond 8 states.

### Decision: Animation

**Choice**: AnimatedSprite2D with separate SpriteFrames per state
**Alternatives**: AnimationTree + StateMachine
**Rationale**: Lower memory, simpler code, perfect for discrete platformer states. No blending needed between idle/run/jump/attack.

### Decision: Touch Controls

**Choice**: Custom Control nodes with Area2D touch detection → Input Actions
**Alternatives**: Godot TouchScreenButton, asset library virtual joystick
**Rationale**: No external deps, full visual control. Writing to Input Actions keeps player.gd input-agnostic.

### Decision: Enemy AI

**Choice**: Timer-based state ticks (0.3s interval) with Area2D detection zones
**Alternatives**: _process polling, Godot NavigationAgents
**Rationale**: Timer ticks reduce CPU on mobile. Detection zones (Area2D) are cheaper than pathfinding for linear levels.

### Decision: Level Geometry

**Choice**: TileMapLayer (Godot 4.3+) with terrain tileset
**Alternatives**: Individual StaticBody2D platforms
**Rationale**: TileMapLayer is purpose-built for 2D levels. Memory-efficient, easy to edit, supports autotiling.

### Decision: Game State

**Choice**: Autoload singleton (GameState)
**Alternatives**: Resource-based save, config file
**Rationale**: Singleton is the Godot convention for cross-scene state. Holds current_level, player_hp, max_hp, damage, checkpoints, furia_state.

## Data Flow

```
Touch Input → Input Actions → player.gd (_physics_process dispatch)
                                    ↓
                              State machine tick
                              (move/jump/attack/dash/hurt/dead)
                                    ↓
                         AnimatedSprite2D.play(state)
                         AttackArea2D.monitoring (on attack)
                                    ↓
                    Enemy hit → health-damage.gd (HP, knockback)
                    Player hit ← enemy attack Area2D overlap
                                    ↓
                         HUD update (health bar, fury cd)
                         GameState save (checkpoint, HP)

Cutscene:
  Trigger Area2D → CutsceneManager.activate()
    → input blocked → camera tween → text display → tap advance → end → resume
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `project.godot` | Create | Godot 4 project configuration |
| `export_presets.cfg` | Create | Android export preset |
| `main.tscn` / `main.gd` | Create | Root scene with game state machine |
| `autoload/game_state.gd` | Create | Persistent cross-level state singleton |
| `autoload/audio_manager.gd` | Create | Audio stub singleton |
| `scenes/player/player.tscn` | Create | Player CharacterBody2D scene |
| `scenes/player/player.gd` | Create | Player controller script |
| `scenes/enemies/soldier.tscn` | Create | Soldier CharacterBody2D scene |
| `scenes/enemies/soldier.gd` | Create | Soldier AI script |
| `scenes/enemies/boss.tscn` | Create | Boss CharacterBody2D scene |
| `scenes/enemies/boss.gd` | Create | Boss AI with phase system |
| `scenes/levels/level_01.tscn` | Create | Farm level (MVP) |
| `scenes/levels/level_02-07.tscn` | Create | Remaining 6 levels |
| `scenes/ui/hud.tscn` / `hud.gd` | Create | HUD overlay |
| `scenes/ui/touch_controls.tscn` / `.gd` | Create | Virtual button container |
| `scenes/ui/virtual_joystick.tscn` / `.gd` | Create | Joystick component |
| `scenes/ui/main_menu.tscn` / `.gd` | Create | Title screen |
| `scenes/cutscene/cutscene_manager.tscn` / `.gd` | Create | Cutscene autoload |
| `assets/sprites/player_placeholder.png` | Create | 32x32 colored character sprite |
| `assets/sprites/tileset_placeholder.png` | Create | 16x16 colored tile sheet |
| `Dockerfile` | Create | Android export Docker build |

## Key Data Structures

```gdscript
# GameState autoload
extends Node
var current_level: int = 1
var max_hp: int = 3
var current_hp: int = 3
var base_damage: float = 1.0
var fury_unlocked: bool = false
var fury_cooldown: float = 0.0
var last_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_level: String = ""

# Player state enum
enum PlayerState { IDLE, RUN, JUMP, FALL, ATTACK_LIGHT, ATTACK_HEAVY, DASH, HURT, DEAD }

# Soldier state enum
enum SoldierState { IDLE, CHASE, ATTACK, HURT, DEAD }
```

## Testing Strategy

No test framework (Strict TDD = false on this project). Manual testing via Godot editor play. Verify: movement feels responsive, combat deals/receives damage correctly, level transitions work, touch controls register all inputs, cutscene blocks/resumes properly.

## Migration / Rollout

3 phases:
1. **MVP** (current): project.godot + player + soldier + level_01 + touch controls + HUD
2. **Full game**: levels 02-07, bosses, cutscenes, progression
3. **Polish**: Dockerfile, Android export, performance, edge-case hardening

Phase 1 must compile and run before starting Phase 2.

## Open Questions

- [ ] Confirm Godot version (4.3 LTS recommended for Docker compatibility)
- [ ] Decide on Android screen orientation (landscape vs sensor)
- [ ] Verify placeholder sprite resolution targets (16px tile? 32px character?)
