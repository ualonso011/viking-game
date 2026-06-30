# Delta for HUD Modernization

## ADDED Requirements

### Requirement: HUD Color Palette

The HUD MUST apply the ash-and-ember color palette: health bar uses ember gradient (`#B2611C` full → darker red at low HP), background elements use dark base `#0D0D14` with ash `#4A4A52` borders. All HUD text MUST use the bundled font.

### Requirement: Top Vignette Gradient

A top-edge vignette gradient MUST be overlaid on the HUD for cinematic feel. The gradient SHOULD go from semi-transparent dark (`#0D0D14` at alpha ~0.6) at the very top to fully transparent at ~15% screen height. This is a `ColorRect` with `GradientTexture2D` or a `TextureRect` with a gradient texture.

### Requirement: Smooth Health Bar Interpolation

Health bar value changes MUST use smooth interpolation. When the target HP changes, the displayed bar value SHALL lerp toward the target over ~0.25 seconds instead of snapping instantly. The lerp MUST use `lerp()` or a tween on the `TextureProgressBar.value` (or equivalent) each frame in `_process()`.

#### Scenario: Health bar animates on damage

- GIVEN the player has 3/3 HP and the health bar shows full
- WHEN the player takes 1 damage (HP becomes 2/3)
- THEN the health bar smoothly decreases from 3 to 2 over ~0.25s
- AND the bar does NOT snap instantly to the new value

#### Scenario: Vignette is visible during gameplay

- GIVEN the player is in any level
- WHEN the HUD is rendered
- THEN a dark gradient is visible at the top edge of the screen
- AND it fades to transparent within the top 15% of the viewport

#### Scenario: HUD uses consistent palette

- GIVEN the HUD is displayed during gameplay
- WHEN any HUD element is inspected
- THEN colors match the ember/ash palette (`#B2611C`, `#0D0D14`, `#4A4A52`)
- AND the bundled font is used for all text labels
