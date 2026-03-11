# Pre-merge checklist

> **Canonical reference:** see [`docs/PRE_MERGE_CHECKLIST.md`](PRE_MERGE_CHECKLIST.md) for the
> full checklist with all sections. The steps below are a quick-start summary.

## Running the automated tests

Open the project in **Godot 4.2+**, then for each script in `tests/`:

1. Open the test scene (e.g. `tests/test_wave_spawner.gd`) in the Godot editor.
2. Press **F6** (Run Current Scene).
3. Check the **Output** panel — the final line must read `N passed, 0 failed.`

Alternatively, attach any `test_*.gd` script to a bare `Node` scene and press **F6** to
run it in isolation.

## Quick smoke-test steps

- [ ] All `tests/test_*.gd` scripts report `0 failed` when run via **F6**.
- [ ] Launch `scenes/ui/main_menu.tscn`, start a run, and verify wave banners,
      between-wave summaries, and game-over buttons all respond correctly.
- [ ] Enable `debug_telemetry_enabled` on the level scene when tuning; confirm
      run id/seed are printed alongside wave metrics in the Output panel.
- [ ] Spot-check spawn safety by kiting enemies during a wave; verify spawns
      always appear outside the minimum distance buffer from the player.
- [ ] Confirm that a wave with `enemy_count = 0` in its `WaveData` resource
      advances automatically without stalling the wave progression.
