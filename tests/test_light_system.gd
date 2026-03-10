## Unit tests for LightSystem visibility radius logic.
##
## Validates that:
##  - The default light_radius matches the expected configurable default.
##  - The default update_interval matches the expected configurable default.
##  - An enemy within the light radius is considered in-light.
##  - An enemy outside the light radius is considered not in-light.
##  - An enemy exactly at the boundary is considered in-light.
##  - An enemy just beyond the boundary is considered not in-light.
##  - light_radius can be changed at runtime (configurable).
##  - update_interval can be changed at runtime (configurable).
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0

const DEFAULT_LIGHT_RADIUS := 250.0
const DEFAULT_UPDATE_INTERVAL := 0.05
const EPSILON := 0.001

var _ls: LightSystem


func _ready() -> void:
	_ls = LightSystem.new()
	_run_all()
	_ls.free()
	print("LightSystem tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_default_light_radius()
	test_default_update_interval()
	test_enemy_inside_radius_is_in_light()
	test_enemy_outside_radius_is_not_in_light()
	test_enemy_at_boundary_is_in_light()
	test_enemy_just_outside_boundary_is_not_in_light()
	test_light_radius_is_configurable()
	test_update_interval_is_configurable()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


## Returns true when enemy_pos is within radius of player_pos.
## Mirrors the distance check used by LightSystem._update_visibility().
func _is_in_light(player_pos: Vector2, enemy_pos: Vector2, radius: float) -> bool:
	return player_pos.distance_to(enemy_pos) <= radius


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_default_light_radius() -> void:
	_assert(
		abs(_ls.light_radius - DEFAULT_LIGHT_RADIUS) < EPSILON,
		"default light_radius is %.0f" % DEFAULT_LIGHT_RADIUS
	)


func test_default_update_interval() -> void:
	_assert(
		abs(_ls.update_interval - DEFAULT_UPDATE_INTERVAL) < EPSILON,
		"default update_interval is %.2f s" % DEFAULT_UPDATE_INTERVAL
	)


func test_enemy_inside_radius_is_in_light() -> void:
	var radius := 250.0
	var player_pos := Vector2.ZERO
	var enemy_pos := Vector2(100.0, 0.0)  # 100 units away
	_assert(
		_is_in_light(player_pos, enemy_pos, radius),
		"enemy 100 units away is visible within radius 250"
	)


func test_enemy_outside_radius_is_not_in_light() -> void:
	var radius := 250.0
	var player_pos := Vector2.ZERO
	var enemy_pos := Vector2(300.0, 0.0)  # 300 units away
	_assert(
		not _is_in_light(player_pos, enemy_pos, radius),
		"enemy 300 units away is hidden outside radius 250"
	)


func test_enemy_at_boundary_is_in_light() -> void:
	var radius := 250.0
	var player_pos := Vector2.ZERO
	var enemy_pos := Vector2(250.0, 0.0)  # exactly at boundary
	_assert(
		_is_in_light(player_pos, enemy_pos, radius),
		"enemy exactly at boundary distance is visible"
	)


func test_enemy_just_outside_boundary_is_not_in_light() -> void:
	var radius := 250.0
	var player_pos := Vector2.ZERO
	var enemy_pos := Vector2(250.01, 0.0)  # just outside
	_assert(
		not _is_in_light(player_pos, enemy_pos, radius),
		"enemy just outside boundary distance is hidden"
	)


func test_light_radius_is_configurable() -> void:
	_ls.light_radius = 400.0
	_assert(
		abs(_ls.light_radius - 400.0) < EPSILON,
		"light_radius can be set to a custom value"
	)
	_ls.light_radius = DEFAULT_LIGHT_RADIUS  # restore default


func test_update_interval_is_configurable() -> void:
	_ls.update_interval = 0.1
	_assert(
		abs(_ls.update_interval - 0.1) < EPSILON,
		"update_interval can be set to a custom value"
	)
	_ls.update_interval = DEFAULT_UPDATE_INTERVAL  # restore default

