# Health & Damage System Specification

## Purpose

Define how HP, damage, knockback, invulnerability, and death work for both player and enemies. Shared system for consistent combat feel.

## Requirements

### Requirement: HP System

All combat entities MUST have integer HP. Player starts with 3 HP per level (upgradable via checkpoints). Soldiers have 3 HP. Bosses have 15 HP. HP MUST NOT go below 0.

#### Scenario: HP reduction
- GIVEN an entity has N HP
- WHEN the entity takes D damage
- THEN HP becomes max(0, N - D)

#### Scenario: HP display
- GIVEN the player has current and max HP
- WHEN HP changes
- THEN the HUD updates the health bar

### Requirement: Knockback

Entities hit by attacks MUST receive knockback. Direction: away from attacker. Distance: ~50px for light attacks, ~100px for heavy attacks. Duration: ~0.2s. Player knockback is disabled during dash.

#### Scenario: Light attack knockback
- GIVEN an enemy is hit by a light attack
- THEN the enemy is pushed 50px away from the attacker over 0.2s

#### Scenario: Heavy attack knockback
- GIVEN an enemy is hit by a heavy attack
- THEN the enemy is pushed 100px away over 0.3s
- AND the enemy is stunned for 0.3s

### Requirement: Invulnerability

Entities MUST be invulnerable for 1s after taking damage. Visual feedback: brief闪烁 (alpha flicker). During invulnerability, damage is ignored.

#### Scenario: Invulnerability after hit
- GIVEN the player just took damage
- WHEN the player is hit again within 1s
- THEN the second hit is ignored
- AND the player sprite flickers to indicate invulnerability

### Requirement: Death

When HP reaches 0, the entity MUST enter dead state. Player: respawns at checkpoint after 2s. Enemy: plays death animation, removed after 1s.

#### Scenario: Player death
- GIVEN the player has 0 HP
- THEN player enters dead state
- AND death animation plays
- AND after 2s, player respawns at last checkpoint with full HP

#### Scenario: Enemy death
- GIVEN an enemy has 0 HP
- THEN the enemy plays death animation
- AND the enemy is queued for deletion after 1s
