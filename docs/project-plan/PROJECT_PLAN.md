# Shadow Hunter – Project Plan

This document is used by GitHub Copilot and automation tools to generate:

- GitHub Issues
- Milestones
- Labels
- Story Points
- Iterations (Sprints)

---

# Milestones

## Prototype
Goal: Playable gameplay loop

Includes:
- Player movement
- Shooting
- Enemy AI
- Spawn system
- XP and leveling

---

## Vertical Slice
Goal: Polished single level

Includes:
- Multiple enemy types
- Weapon upgrades
- Boss fight
- Improved UI

---

## Demo
Goal: Content-complete demo

Includes:
- 3 environments
- 15+ enemies
- 3 bosses
- Audio and progression

---

# Iterations

| Sprint | Focus |
|------|------|
| Sprint 1 | Player |
| Sprint 2 | Enemy AI |
| Sprint 3 | Combat |
| Sprint 4 | Progression |
| Sprint 5 | Vertical slice |
| Sprint 6 | Demo content |

---

# Issues

## Player Systems

### Player Movement Controller
Labels: system:player
Milestone: Prototype
Sprint: 1
Story Points: 3

Description:
Implement top-down movement system for a 2D action shooter.

Acceptance Criteria:
- WASD movement in all four directions
- Physics-based
- Smooth movement relative to top-down camera

---

### Mouse Aim/Rotate
Labels: system:player
Milestone: Prototype
Sprint: 1
Story Points: 2

Description:
Implement mouse aiming and player rotation for top-down perspective.

Acceptance Criteria:
- Player rotates to face mouse cursor
- Aiming direction updates in real time
- Adjustable sensitivity

---

## Combat

### Shooting System
Labels: system:combat
Milestone: Prototype
Sprint: 1
Story Points: 3

Description:
Implement weapon shooting system.

Acceptance Criteria:
- Mouse click fires weapon
- Fire rate limit
- Basic muzzle flash

---

## Light

### Light System
Labels: system:lighting
Milestone: Prototype
Sprint: 1
Story Points: 3

Description:
Implement the core light radius visibility system. The player's lantern emits a circular light that reveals enemies hidden in darkness, forming the central gameplay mechanic.

Acceptance Criteria:
- Player lantern emits a circular light radius
- Enemies outside the light radius are hidden in darkness
- Enemies entering the light radius become visible to the player
- Light radius size is configurable

---

## Enemies

### Basic Enemy AI
Labels: system:enemy
Milestone: Prototype
Sprint: 2
Story Points: 5

Description:
Enemy detects and moves toward player.

Acceptance Criteria:
- Enemy detects player
- Enemy navigates toward player
- Enemy attacks player

---

### Enemy Damage
Labels: system:enemy
Milestone: Prototype
Sprint: 2
Story Points: 3

Description:
Enemies take damage and die.

Acceptance Criteria:
- HP system
- Death logic
- XP drop

---

## Spawning

### Enemy Spawn Manager
Labels: system:spawn
Milestone: Prototype
Sprint: 3
Story Points: 5

Description:
System responsible for spawning enemies.

Acceptance Criteria:
- Spawn points
- Timed spawning
- Difficulty scaling

---

## Progression

### XP System
Labels: system:progression
Milestone: Prototype
Sprint: 4
Story Points: 3

Description:
Enemies drop XP and player collects it.

Acceptance Criteria:
- XP drops
- XP pickup
- XP counter

---

### Level System
Labels: system:progression
Milestone: Prototype
Sprint: 4
Story Points: 5

Description:
Player levels up when XP threshold is reached.

Acceptance Criteria:
- XP bar
- Level increases
- Level-up trigger

---

## Combat Feel

### Combat Feedback — Enemy Hit Flash
Labels: system:combat
Milestone: Vertical Slice
Sprint: 5
Story Points: 2

Description:
Enemies briefly flash bright when hit so players can immediately perceive that damage landed.

Acceptance Criteria:
- Enemy sprite flashes a bright colour for a short duration on each hit
- Flash does not play while the enemy is already dying
- Configurable flash colour and duration

---

### Combat Feedback — Player Damage Indicator
Labels: system:combat
Milestone: Vertical Slice
Sprint: 5
Story Points: 2

Description:
A screen overlay briefly appears whenever the player takes damage, giving immediate visual confirmation.

Acceptance Criteria:
- Semi-transparent red overlay appears on the screen edge when player takes damage
- Overlay fades out automatically after a short duration
- Overlay does not activate when damage is blocked by invulnerability frames
- Rapid successive hits overwrite the previous timer without stacking

---

### Combat Feedback — Projectile Tracer and Muzzle Effect
Labels: system:combat
Milestone: Vertical Slice
Sprint: 5
Story Points: 3

Description:
Projectiles render a short motion trail and a brief flash is spawned at the impact point so hits feel punchy.

Acceptance Criteria:
- Each projectile renders a Line2D motion tracer behind it
- An ImpactEffect node is spawned at the collision point on hit
- Effect self-destructs after its animation completes (no node leaks)

---

### Combat Feedback — Enemy Death Animation
Labels: system:combat
Milestone: Vertical Slice
Sprint: 5
Story Points: 2

Description:
Enemies fade out visually when killed rather than disappearing instantly, giving clear death confirmation.

Acceptance Criteria:
- Enemy body tweens to zero alpha over a short duration after death
- Collision and movement stop immediately at death before the visual fade finishes
- XP and scoring signals fire before the visual fade begins

---

## HUD

### HUD — Wave Progress Clarity
Labels: system:ui
Milestone: Vertical Slice
Sprint: 5
Story Points: 3

Description:
The HUD clearly communicates which wave the player is on and what to expect next.

Acceptance Criteria:
- Wave label shows current and total waves (e.g. "Wave 02 / 05" — exact formatting is illustrative)
- A banner appears at the start of each wave announcing the wave number
- A brief summary banner displays after each wave is cleared, showing wave number and score

---

### HUD — End Screen with Clear CTA
Labels: system:ui
Milestone: Vertical Slice
Sprint: 5
Story Points: 2

Description:
The game-over and run-complete screen provides the player's final stats and clear next-action buttons.

Acceptance Criteria:
- End screen shows final wave reached and score
- Retry and Main Menu buttons are visible and focussed for immediate input
- Screen is not shown while a wave is in progress

---

## Balance and Difficulty

### Balance Pass with Wave Telemetry
Labels: system:spawn
Milestone: Vertical Slice
Sprint: 5
Story Points: 3

Description:
Use the existing wave telemetry fields to gather data and tune difficulty parameters so the five-wave arc feels escalating but fair.

Acceptance Criteria:
- WaveData telemetry fields (clear-time, damage taken, kills per minute) are actively logged per wave
- Wave parameters (enemy_count, spawn_delay, health/speed/damage scale) are tuned using logged data
- At least 70% of internal runs complete all waves without the player quitting early

---

## Wave Content

### Wave Content Variants — Mixed Enemy Spawns
Labels: system:spawn
Milestone: Vertical Slice
Sprint: 5
Story Points: 5

Description:
Give each wave a distinct encounter identity by using the enemy_scene_pool to introduce mixed enemy compositions.

Acceptance Criteria:
- At least three wave identity types defined (e.g. rush, attrition, burst)
- Waves beyond wave 2 use enemy_scene_pool for mixed enemy type spawning
- Spawn safety radius prevents enemies from appearing directly on top of the player
- Waves feel noticeably different in pacing, not just in raw numbers

---

## State and Polish

### Game State and Pause Polish
Labels: system:ui
Milestone: Vertical Slice
Sprint: 5
Story Points: 3

Description:
All game state transitions (pause, retry, menu) are consistent and free of input-doubling or leftover state.

Acceptance Criteria:
- Pause, retry, and main menu transitions complete cleanly without residual state
- Input actions do not fire twice when changing scenes
- A run seed or run ID is written to the log on each run start for reproducibility

---

## Test and Delivery Hygiene

### Wave Progression Tests and Pre-Merge Checklist
Labels: system:spawn
Milestone: Vertical Slice
Sprint: 5
Story Points: 2

Description:
Expand automated test coverage for wave progression edge-cases and establish a standard pre-merge check routine.

Acceptance Criteria:
- Unit tests cover wave progression edge-cases (e.g. zero enemies, missing spawn points, pool selection)
- A pre-merge checklist document exists in the repository
- The checklist is runnable by any team member without ad-hoc steps
