# Enemy System Specification

## Purpose

Define enemy types: Soldier (basic melee) and Boss (multi-phase). Both use simple AI with detection, chase, and attack states.

## Requirements

### Requirement: Soldier AI

The Soldier MUST have 3 states: idle, chase, attack. Detection range: ~200px. Attack range: ~30px. Attack cooldown: ~1.5s. HP: 3. Damage: 1. Knockback on hit.

#### Scenario: Soldier detects player
- GIVEN the Soldier is in idle state
- WHEN the player enters detection range (200px)
- THEN the Soldier transitions to chase state
- AND moves toward the player

#### Scenario: Soldier attacks player
- GIVEN the Soldier is in chase state
- WHEN the Soldier is within attack range (30px)
- THEN the Soldier transitions to attack state
- AND performs a melee attack
- AND enters cooldown for 1.5s

#### Scenario: Soldier takes damage
- GIVEN the Soldier has 3 HP
- WHEN the Soldier is hit by player attack
- THEN HP decreases by damage amount
- AND the Soldier receives knockback
- AND the Soldier is briefly stunned (0.3s)

#### Scenario: Soldier dies
- GIVEN the Soldier has 1 HP
- WHEN the Soldier is hit
- THEN HP becomes 0
- AND the Soldier plays death animation
- AND the Soldier is removed after 1s

### Requirement: Boss AI

The Boss MUST have 2-3 phases triggered by HP thresholds. Phase 1 (100-66%): fast attacks. Phase 2 (66-33%): heavy attacks + brief pauses. Phase 3 (33-0%): enraged (faster + stronger). HP: 15. Damage varies by phase.

#### Scenario: Boss phase transition
- GIVEN the Boss has 15 max HP
- WHEN Boss HP drops below 66%
- THEN Boss transitions to Phase 2
- AND attack pattern changes to heavy strikes with pauses
- WHEN Boss HP drops below 33%
- THEN Boss transitions to Phase 3
- AND attack speed and damage increase

#### Scenario: Boss fast attack (Phase 1)
- GIVEN the Boss is in Phase 1
- WHEN the player is within attack range
- THEN the Boss performs a fast strike (1 damage, 0.5s windup)

#### Scenario: Boss heavy attack (Phase 2)
- GIVEN the Boss is in Phase 2
- WHEN the Boss finishes a defensive pause
- THEN the Boss performs a heavy slam (2 damage, 1s windup, area effect)

#### Scenario: Boss enraged (Phase 3)
- GIVEN the Boss is in Phase 3
- THEN attack speed increases by 30%
- AND damage increases by 50%
- AND visual effect (red tint) indicates enrage
