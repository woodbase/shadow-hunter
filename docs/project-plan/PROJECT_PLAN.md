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
Implement basic FPS movement system.

Acceptance Criteria:
- WASD movement
- Physics based
- Smooth movement

---

### Mouse Look
Labels: system:player
Milestone: Prototype
Sprint: 1
Story Points: 2

Description:
Implement mouse camera rotation.

Acceptance Criteria:
- Horizontal rotation
- Vertical rotation
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
