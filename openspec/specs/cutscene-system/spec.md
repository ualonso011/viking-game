# Cutscene System Specification

## Purpose

Define the cutscene manager that displays narrative text, blocks player input, and controls camera movement during story moments.

## Requirements

### Requirement: CutsceneManager

The system MUST have a CutsceneManager autoload (singleton). It MUST block player input, display text in a CanvasLayer overlay, move camera to target positions with Tween, and resume gameplay when finished.

#### Scenario: Play cutscene
- GIVEN the player enters a cutscene trigger Area2D
- THEN CutsceneManager activates
- AND player input is blocked
- AND camera moves to the cutscene focus point
- AND text lines display sequentially
- WHEN all text is shown
- THEN control returns to the player

### Requirement: Text Display

Text MUST appear in a styled panel at the bottom of the screen. Lines appear one at a time. Player taps to advance to the next line. Text supports speaker name prefix (e.g., "Einar: ...").

#### Scenario: Text progression
- GIVEN a cutscene is playing
- WHEN the player taps the screen
- THEN the current text is replaced by the next line
- WHEN all lines are consumed
- THEN the cutscene ends

### Requirement: Camera Control

During cutscenes, the camera MAY move to predefined positions using Tween. Camera follows Tween path and stops at the end. After cutscene, camera returns to following the player.

#### Scenario: Camera pan
- GIVEN a cutscene starts
- THEN the camera smoothly pans to the cutscene target over 2s
- AND holds on the target position
- WHEN the cutscene ends
- THEN the camera returns to following the player instantly
