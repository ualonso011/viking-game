# Main Menu Specification

## Purpose

Define the Viking-themed main menu visual identity, animations, and interactions.

## Requirements

### Requirement: Viking-Themed Visual Identity

The main menu MUST display the subtitle "Un viaje vikingo de ceniza y acero". The color palette MUST use: dark base `#0D0D14`, ember accent `#B2611C`, ash `#4A4A52`. Typography: bold weight for the title, regular weight for subtitle and button text. A bundled free font (system default or open-source Viking-compatible) SHALL be used — no custom paid fonts.

### Requirement: Title Fade-In Animation

On scene load, the title MUST fade in from invisible to fully visible. The transition MUST use a tween interpolating `modulate.a` from 0 to 1 over 0.6 seconds. The subtitle SHOULD fade in with a 0.2s delay after the title.

### Requirement: Button Hover Glow

Menu buttons ("EMPEZAR", etc.) SHOULD display a subtle hover/press glow effect. The glow MUST use the ember accent color `#B2611C` at low intensity. The effect SHOULD be a `modulate` or `self_modulate` tween on hover/press state.

#### Scenario: Title fades in on menu load

- GIVEN the main menu scene loads
- WHEN the scene enters the tree
- THEN the title text fades from alpha 0 to alpha 1 over 0.6 seconds
- AND the subtitle fades in 0.2s after the title starts

#### Scenario: Button press starts game with visual feedback

- GIVEN the main menu is fully displayed
- WHEN the user taps "EMPEZAR"
- THEN the button shows a brief ember glow press effect
- AND `game_manager.start_game()` is called

#### Scenario: Color palette consistency

- GIVEN the main menu is displayed
- WHEN any UI element is inspected
- THEN background uses `#0D0D14`, accents use `#B2611C`, secondary text uses `#4A4A52`
