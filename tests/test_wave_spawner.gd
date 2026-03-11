## Unit tests for WaveSpawner wave data and spawn safety helpers.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("WaveSpawner tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_wave_data_overrides_total_waves()
	test_wave_enemy_count_negative_is_clamped()
	test_spawn_point_respects_min_distance()
	test_spawn_position_is_pushed_outside_safety_radius()
	test_spawn_point_uses_farthest_when_all_are_near()
	test_missing_spawn_point_returns_null()
	test_wave_enemy_scene_override_uses_wave_data_scene()
	test_wave_enemy_scene_missing_override_falls_back()
	test_wave_enemy_scene_pool_selects_from_pool()
	test_pool_with_all_null_entries_falls_back_to_enemy_scene()
	test_get_total_waves_public_accessor()
	test_get_total_waves_falls_back_to_total_waves()
	test_transitioning_guard_starts_false()
	test_start_wave_guard_clears_starting_flag()
	test_enemy_removed_advances_single_wave_step()
	test_zero_enemy_wave_advances_immediately()
	test_wave_completed_signal_fires_for_zero_enemy_wave()
	test_difficulty_multiplier_at_wave_zero_is_1()
	test_difficulty_multiplier_scales_linearly()
	test_procedural_count_scales_with_difficulty()
	test_data_driven_count_ignores_difficulty_scale()
	test_wave_data_telemetry_fields_default_to_zero()
	test_wave_data_telemetry_fields_are_writable()
	test_wave_data_tuned_difficulty_scales()
	test_wave_identity_defaults_to_standard()
	test_wave_identity_uses_wave_data_identity()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_wave(enemy_count: int, spawn_delay: float) -> WaveData:
	var wave := WaveData.new()
	wave.enemy_count = enemy_count
	wave.spawn_delay = spawn_delay
	return wave


func test_wave_data_overrides_total_waves() -> void:
	var spawner := WaveSpawner.new()
	spawner.total_waves = 99
	spawner.wave_data_list = [_make_wave(3, 0.2), _make_wave(4, 0.3)]
	_assert(spawner._get_total_waves() == 2, "wave_data_list size controls total waves")


func test_wave_enemy_count_negative_is_clamped() -> void:
	var spawner := WaveSpawner.new()
	spawner.wave_data_list = [_make_wave(-5, 0.3)]
	_assert(spawner._get_wave_enemy_count(0) == 0, "negative wave enemy count is clamped to zero")


func test_spawn_point_respects_min_distance() -> void:
	var spawner := WaveSpawner.new()
	var player := Node2D.new()
	player.global_position = Vector2.ZERO
	spawner._player = player
	spawner._players = [player]
	spawner.min_spawn_distance_from_player = 200.0
	spawner.spawn_retry_count = 1

	var near := Marker2D.new()
	near.global_position = Vector2(100.0, 0.0)
	var far := Marker2D.new()
	far.global_position = Vector2(400.0, 0.0)
	spawner.spawn_points = [near, far]

	var selected := spawner._select_spawn_point()
	_assert(selected == far, "spawn selection returns a valid far point via fallback")


func test_spawn_position_is_pushed_outside_safety_radius() -> void:
	var spawner := WaveSpawner.new()
	var player := Node2D.new()
	player.global_position = Vector2.ZERO
	spawner._players = [player]
	spawner.min_spawn_distance_from_player = 150.0

	var adjusted := spawner._get_safe_spawn_position(Vector2(10.0, 0.0), spawner._get_active_players())
	_assert(adjusted.distance_to(player.global_position) >= 150.0, "spawn position is offset to satisfy safety radius")


func test_spawn_point_uses_farthest_when_all_are_near() -> void:
	var spawner := WaveSpawner.new()
	var player := Node2D.new()
	player.global_position = Vector2.ZERO
	spawner._players = [player]
	spawner.min_spawn_distance_from_player = 300.0

	var very_near := Marker2D.new()
	very_near.global_position = Vector2(40.0, 0.0)
	var less_near := Marker2D.new()
	less_near.global_position = Vector2(220.0, 0.0)
	spawner.spawn_points = [very_near, less_near]

	var selected := spawner._select_spawn_point()
	_assert(selected == less_near, "when no point clears the safety radius, the farthest candidate is used")


func test_missing_spawn_point_returns_null() -> void:
	var spawner := WaveSpawner.new()
	spawner.spawn_points = []
	_assert(spawner._select_spawn_point() == null, "empty spawn list returns null")


func test_wave_enemy_scene_override_uses_wave_data_scene() -> void:
	var spawner := WaveSpawner.new()
	var fallback_enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var variant_enemy_scene: PackedScene = load("res://scenes/enemies/enemy_striker.tscn")
	spawner.enemy_scene = fallback_enemy_scene

	var wave := _make_wave(4, 0.4)
	wave.enemy_scene = variant_enemy_scene
	spawner.wave_data_list = [wave]

	_assert(spawner._get_wave_enemy_scene(0) == variant_enemy_scene, "wave-specific enemy scene overrides fallback")
	_assert(spawner._get_wave_enemy_scene(10) == fallback_enemy_scene, "fallback enemy scene is used outside wave_data_list")


func test_wave_enemy_scene_missing_override_falls_back() -> void:
	var spawner := WaveSpawner.new()
	var fallback_enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	spawner.enemy_scene = fallback_enemy_scene

	var wave := _make_wave(3, 0.5)
	spawner.wave_data_list = [wave]

	_assert(spawner._get_wave_enemy_scene(0) == fallback_enemy_scene, "fallback enemy scene is used when wave enemy_scene is null")


func test_wave_enemy_scene_pool_selects_from_pool() -> void:
	var spawner := WaveSpawner.new()
	var base_enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var striker_enemy_scene: PackedScene = load("res://scenes/enemies/enemy_striker.tscn")

	var wave := _make_wave(6, 0.3)
	wave.enemy_scene_pool = [base_enemy_scene, striker_enemy_scene]
	spawner.wave_data_list = [wave]

	var selected := spawner._get_wave_enemy_scene(0)
	_assert(selected == base_enemy_scene or selected == striker_enemy_scene,
		"enemy_scene_pool returns one of the configured scenes when set")


func test_get_total_waves_public_accessor() -> void:
	var spawner := WaveSpawner.new()
	spawner.wave_data_list = [_make_wave(3, 0.2), _make_wave(4, 0.3), _make_wave(2, 0.4)]
	_assert(spawner.get_total_waves() == 3, "get_total_waves() returns wave_data_list size when list is set")


func test_get_total_waves_falls_back_to_total_waves() -> void:
	var spawner := WaveSpawner.new()
	spawner.total_waves = 5
	spawner.wave_data_list = []
	_assert(spawner.get_total_waves() == 5, "get_total_waves() falls back to total_waves when wave_data_list is empty")


func test_transitioning_guard_starts_false() -> void:
	var spawner := WaveSpawner.new()
	_assert(spawner.is_transitioning() == false, "is_transitioning() is false on a new WaveSpawner")


func test_start_wave_guard_clears_starting_flag() -> void:
	var spawner := WaveSpawner.new()
	spawner._wave_in_progress = true
	spawner._start_wave(0)
	_assert(spawner._starting_wave == false, "_start_wave guard clears _starting_wave when wave is already active")


func test_enemy_removed_advances_single_wave_step() -> void:
	var spawner := WaveSpawner.new()
	spawner.between_wave_delay = 0.0
	spawner._active_enemies = 1
	spawner._current_wave = 0
	spawner._wave_in_progress = true
	spawner._on_enemy_removed(true)
	_assert(spawner._current_wave == 1, "_on_enemy_removed increments current wave once")


func test_difficulty_multiplier_at_wave_zero_is_1() -> void:
	var spawner := WaveSpawner.new()
	spawner.health_scale_per_wave = 0.15
	_assert(
		is_equal_approx(spawner._get_difficulty_multiplier(spawner.health_scale_per_wave, 0), 1.0),
		"difficulty multiplier is 1.0 on wave 0 regardless of scale"
	)


func test_difficulty_multiplier_scales_linearly() -> void:
	var spawner := WaveSpawner.new()
	# Wave 4 with 0.10 scale/wave: 1.0 + 4 * 0.10 = 1.40
	var mult: float = spawner._get_difficulty_multiplier(0.10, 4)
	_assert(is_equal_approx(mult, 1.40), "difficulty multiplier grows linearly: wave 4 with 0.10 scale = 1.40")


func test_procedural_count_scales_with_difficulty() -> void:
	var spawner := WaveSpawner.new()
	spawner.enemies_per_wave = 5
	spawner.count_scale_per_wave = 0.20
	spawner.wave_data_list = []
	# Wave 0: 5 * (1.0 + 0 * 0.20) = 5; Wave 5: 5 * (1.0 + 5 * 0.20) = 5 * 2.0 = 10
	_assert(spawner._get_wave_enemy_count(0) == 5, "procedural enemy count matches base at wave 0")
	_assert(spawner._get_wave_enemy_count(5) == 10, "procedural enemy count doubles at wave 5 with 0.20 scale/wave")


func test_data_driven_count_ignores_difficulty_scale() -> void:
	var spawner := WaveSpawner.new()
	spawner.count_scale_per_wave = 0.50
	var wave := _make_wave(6, 0.3)
	spawner.wave_data_list = [wave]
	_assert(spawner._get_wave_enemy_count(0) == 6, "data-driven enemy count is used as-is and ignores count_scale_per_wave")


func test_wave_data_telemetry_fields_default_to_zero() -> void:
	var wave := WaveData.new()
	_assert(is_zero_approx(wave.clear_time_sec), "WaveData.clear_time_sec defaults to 0.0")
	_assert(is_zero_approx(wave.damage_taken), "WaveData.damage_taken defaults to 0.0")
	_assert(is_zero_approx(wave.kills_per_minute), "WaveData.kills_per_minute defaults to 0.0")


func test_wave_data_telemetry_fields_are_writable() -> void:
	var wave := WaveData.new()
	wave.clear_time_sec = 25.5
	wave.damage_taken = 18.3
	wave.kills_per_minute = 22.0
	_assert(is_equal_approx(wave.clear_time_sec, 25.5), "WaveData.clear_time_sec is writable")
	_assert(is_equal_approx(wave.damage_taken, 18.3), "WaveData.damage_taken is writable")
	_assert(is_equal_approx(wave.kills_per_minute, 22.0), "WaveData.kills_per_minute is writable")


func test_wave_data_tuned_difficulty_scales() -> void:
	# Verify that the tuned default scale values produce multipliers within a
	# fair escalation range across all five waves.
	var spawner := WaveSpawner.new()
	# health_scale_per_wave default is 0.12 → wave 5 (index 4) should be 1.48x
	var wave5_health: float = spawner._get_difficulty_multiplier(spawner.health_scale_per_wave, 4)
	_assert(wave5_health < 1.6, "wave-5 health multiplier stays below 1.6x for fairness")
	_assert(wave5_health > 1.0, "wave-5 health multiplier still escalates beyond 1.0x")
	# speed_scale_per_wave default is 0.08 → wave 5 should be 1.32x
	var wave5_speed: float = spawner._get_difficulty_multiplier(spawner.speed_scale_per_wave, 4)
	_assert(wave5_speed < 1.5, "wave-5 speed multiplier stays below 1.5x for fairness")
	_assert(wave5_speed > 1.0, "wave-5 speed multiplier still escalates beyond 1.0x")


func test_wave_identity_defaults_to_standard() -> void:
	var spawner := WaveSpawner.new()
	var wave := WaveData.new()
	spawner.wave_data_list = [wave]
	_assert(spawner._get_wave_identity(spawner.wave_data_list[0]) == &"standard", "wave identity defaults to standard when unset")


func test_wave_identity_uses_wave_data_identity() -> void:
	var spawner := WaveSpawner.new()
	var wave := WaveData.new()
	wave.wave_identity = &"rush"
	spawner.wave_data_list = [wave]
	_assert(spawner._get_wave_identity(spawner.wave_data_list[0]) == &"rush", "wave identity reads value from WaveData")


func test_zero_enemy_wave_advances_immediately() -> void:
	var spawner := WaveSpawner.new()
	spawner.between_wave_delay = 0.0
	spawner.wave_data_list = [_make_wave(0, 0.0), _make_wave(3, 0.2)]
	spawner._wave_in_progress = false
	spawner._starting_wave = false
	spawner._current_wave = 0
	spawner._start_wave(0)
	_assert(spawner._current_wave == 1, "zero-enemy wave advances current_wave immediately without hanging")


func test_wave_completed_signal_fires_for_zero_enemy_wave() -> void:
	var spawner := WaveSpawner.new()
	spawner.between_wave_delay = 0.0
	spawner.wave_data_list = [_make_wave(0, 0.0), _make_wave(3, 0.2)]
	spawner._wave_in_progress = false
	spawner._starting_wave = false
	spawner._current_wave = 0
	var completed_wave_number: int = -1
	spawner.wave_completed.connect(func(n: int) -> void: completed_wave_number = n)
	spawner._start_wave(0)
	_assert(completed_wave_number == 1, "wave_completed signal fires with wave number 1 for a zero-enemy wave")


func test_pool_with_all_null_entries_falls_back_to_enemy_scene() -> void:
	var spawner := WaveSpawner.new()
	var fallback: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	spawner.enemy_scene = fallback
	var wave := _make_wave(3, 0.3)
	wave.enemy_scene_pool = [null, null]
	spawner.wave_data_list = [wave]
	_assert(spawner._get_wave_enemy_scene(0) == fallback,
		"all-null enemy_scene_pool entries fall back to enemy_scene")
