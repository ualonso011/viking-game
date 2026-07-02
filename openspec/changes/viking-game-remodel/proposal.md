# Proposal: Viking Game Remodel

## Intent

Turn **Las Cenizas del Oso** from a complete but visually silent prototype into a presentable Android game. Replace visual/audio layers, complete menus/story surfaces, and preserve mechanics/export.

## Scope

### In Scope
- Illustrated PNGs: characters, platforms, backgrounds, portraits, UI, icon.
- OFL font: Cinzel or Uncial Antiqua, applied through Godot Theme resources.
- Single-page menu: Start, Options, Credits, Exit.
- Pause, game-over, options, credits, HUD.
- OpenGameArt CC0/CC-BY music, combat/UI SFX, ambience, attribution.
- L3, L4, L6 cutscenes with portraits/backgrounds.
- Parallax backgrounds, 9-slice panels, Android export verification.

### Out of Scope
- Mechanics, combat balance, level count, bosses, progression rewrite.
- Save/load, multiplayer, leaderboards.
- Level refactors unless required for UI/audio.

## Capabilities

### New Capabilities
- `audio-system`: Music, SFX, ambience, volume, attribution.
- `ui-surfaces`: Pause, game-over, options, credits.
- `visual-theme`: Font, panels, icon, parallax, styling.

### Modified Capabilities
- `sprite-assets`: Replace null/placeholder visuals with illustrated PNGs.
- `main-menu`: Expand one-button menu into single-page structure.
- `hud-system`: Improve health, fury, checkpoint, cinematic styling.
- `cutscene-system`: Add story beats, portraits, backgrounds, ambience.

## Approach

Keep logic intact. Compose scenes/resources around current flow, use `assets/themes/viking_theme.tres`, wire audio through `autoload/audio_manager.gd`, and assign assets in scenes instead of changing mechanics.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `assets/sprites/`, `assets/fonts/`, `assets/audio/`, `assets/themes/` | New/Modified | Art, font, sound, theme. |
| `scenes/ui/` | New/Modified | Menu, HUD, pause, game-over, options, credits. |
| `scenes/cutscene/`, `autoload/narrative_db.gd` | Modified | Portraits, backgrounds, dialogue. |
| `autoload/audio_manager.gd` | Modified | Music/SFX/ambience API. |
| `scenes/levels/level_03/04/06.gd` | Modified | Trigger missing cutscenes only. |
| `icon.svg`, export | Modified | Viking icon; Android-safe assets. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Asset license mistakes | Medium | OFL fonts, CC0/CC-BY audio, attribution. |
| Flow regression | Low | Compose UI scenes; avoid gameplay rewrites. |
| Inconsistent art | Medium | One palette/style guide; mobile-scaled PNGs. |
| APK size/export issue | Medium | Compress textures/audio and verify Android export. |

## Rollback Plan

Revert the remodel change folder and resource assignments. Mechanics stay isolated, so rollback restores prior scenes, theme, icon, and audio stubs without migration.

## Dependencies

- Cinzel or Uncial Antiqua OFL font.
- OpenGameArt CC0/CC-BY audio with attribution.
- Mobile-sized illustrated PNG assets.

## Success Criteria

- [ ] No player/enemy/boss/UI sprite renders null or invisible.
- [ ] UI uses bundled Viking font and theme.
- [ ] Main, pause, game-over, options, credits, HUD work on Android.
- [ ] Music, SFX, and ambience play through `audio_manager.gd`.
- [ ] L3, L4, L6 cutscenes match existing tone.
- [ ] Android export builds and launches.
