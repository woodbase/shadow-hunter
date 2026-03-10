# Pre-Merge Checklist

Run these steps before merging any branch that touches gameplay, systems, or data.
Tick every box or note the reason it was skipped.

---

## 1. Code Quality

- [ ] No GDScript errors or warnings in the Godot editor output
- [ ] No debug `print()` statements left in changed files (unless intentional logging)
- [ ] Changed scripts follow existing naming and style conventions

## 2. Tests

- [ ] All test scenes in `tests/` run without `[FAIL]` lines
  - Open each `test_*.gd` scene in Godot and press **F6** (Run Current Scene); verify the summary line printed to the Output panel shows `0 failed`
- [ ] New functionality has matching test cases where the test infrastructure allows it

## 3. Gameplay Smoke Test

Open the project in Godot and play through `scenes/levels/test_level.tscn`:

- [ ] Player spawns and moves correctly (WASD + mouse aim)
- [ ] Weapon fires and projectiles register hits on enemies
- [ ] Enemies take damage, flash on hit, and fade on death
- [ ] XP orbs spawn on enemy death and are collected by the player
- [ ] XP bar and level label update correctly
- [ ] All five waves complete without errors
- [ ] Wave banners appear at wave start and summary banners appear on wave clear
- [ ] Game-over / run-complete screen shows final wave and score, with working Retry and Menu buttons
- [ ] Player damage overlay flashes when hit
- [ ] No orphaned nodes or console errors at any point in the run

## 4. Wave Data Integrity

- [ ] All `data/waves/wave_0*.tres` files load without errors
- [ ] No wave has `enemy_count` of 0 unintentionally
- [ ] Waves using `enemy_scene_pool` reference valid scenes

## 5. Audio

- [ ] Key SFX play at the expected moments: shoot, hit, enemy alert, death, level-up
- [ ] No audio bus errors in the Godot output

## 6. Scene and Resource References

- [ ] No missing resource errors (`ERROR: res://...` not found) in the editor output
- [ ] No broken `@onready` node paths (look for `null` access errors on `_ready`)

## 7. Git Hygiene

- [ ] Branch is rebased on (or merged from) the latest `main`
- [ ] Commit messages are clear and describe *what* changed and *why*
- [ ] No unintended large binary assets or `.godot/` cache files included

---

*If a step cannot be completed, document the reason as a comment on the pull request.*
