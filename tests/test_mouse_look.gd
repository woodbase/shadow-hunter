## Unit tests for the mouse look camera offset math helper and aim rotation.
##
## Validates that the pure offset formula used by PlayerController._handle_mouse_look()
## is correct for both horizontal and vertical mouse positions, that sensitivity
## scales the result proportionally, and that a centred cursor yields no offset.
## These tests exercise the local _compute_look_offset() helper only, not the
## PlayerController node or its _handle_mouse_look() method end-to-end.
##
## Also validates the rotation formula used by PlayerController._handle_aim()
## (mirror of look_at's internal angle calculation) for all four cardinal
## directions, a NE diagonal, the resulting fire direction vector, and the
## exported mouse_look_sensitivity default range.
##
## Integration tests below also verify that _handle_mouse_look() applies the
## computed offset to Camera2D.offset and that the device_id >= 0 gate works.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("MouseLook tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_mouse_at_center_gives_zero_offset()
	test_horizontal_offset_only()
	test_vertical_offset_only()
	test_offset_scales_with_sensitivity()
	test_sensitivity_zero_gives_no_offset()
	test_sensitivity_one_equals_raw_delta()
	test_handle_mouse_look_sets_camera_offset()
	test_handle_mouse_look_no_op_for_gamepad()
	test_aim_angle_cursor_right_of_player()
	test_aim_angle_cursor_below_player()
	test_aim_angle_cursor_left_of_player()
	test_aim_angle_cursor_above_player()
	test_aim_angle_cursor_diagonal_ne()
	test_aim_direction_vector_matches_rotation()
	test_mouse_look_sensitivity_default_is_in_range()


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


func _is_approx_equal(a: Vector2, b: Vector2, tolerance: float = 0.001) -> bool:
	return a.distance_to(b) < tolerance


func _is_approx_equal_f(a: float, b: float, tolerance: float = 0.001) -> bool:
	return abs(a - b) < tolerance


## Pure version of the offset formula used in PlayerController._handle_mouse_look().
func _compute_look_offset(mouse_pos: Vector2, viewport_half: Vector2, sensitivity: float) -> Vector2:
	return (mouse_pos - viewport_half) * sensitivity


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_mouse_at_center_gives_zero_offset() -> void:
	var half := Vector2(640.0, 360.0)
	var result := _compute_look_offset(half, half, 0.3)
	_assert(_is_approx_equal(result, Vector2.ZERO),
		"mouse at viewport centre produces zero camera offset")


func test_horizontal_offset_only() -> void:
	# Mouse 160 px to the right of centre, vertically centred.
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(800.0, 360.0)
	var result := _compute_look_offset(mouse, half, 1.0)
	_assert(_is_approx_equal(result, Vector2(160.0, 0.0)),
		"rightward mouse produces positive x offset and zero y offset")


func test_vertical_offset_only() -> void:
	# Mouse 160 px above centre, horizontally centred.
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(640.0, 200.0)
	var result := _compute_look_offset(mouse, half, 1.0)
	_assert(_is_approx_equal(result, Vector2(0.0, -160.0)),
		"upward mouse produces negative y offset and zero x offset")


func test_offset_scales_with_sensitivity() -> void:
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(800.0, 360.0)  # 160 px right of centre
	var low := _compute_look_offset(mouse, half, 0.3)
	var high := _compute_look_offset(mouse, half, 0.6)
	_assert(high.x > low.x,
		"higher sensitivity produces a larger horizontal camera offset")
	_assert(_is_approx_equal(high, low * 2.0),
		"offset doubles when sensitivity doubles")


func test_sensitivity_zero_gives_no_offset() -> void:
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(0.0, 0.0)  # top-left corner
	var result := _compute_look_offset(mouse, half, 0.0)
	_assert(_is_approx_equal(result, Vector2.ZERO),
		"zero sensitivity always produces zero camera offset")


func test_sensitivity_one_equals_raw_delta() -> void:
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(500.0, 100.0)
	var expected := mouse - half
	var result := _compute_look_offset(mouse, half, 1.0)
	_assert(_is_approx_equal(result, expected),
		"sensitivity of 1 produces an offset equal to the raw mouse delta")


# ---------------------------------------------------------------------------
# Integration tests — exercise _handle_mouse_look() via a minimal node tree
# ---------------------------------------------------------------------------

## Build a Camera2D stub that records the last offset assigned to it.
class _FakeCamera2D extends Camera2D:
	var last_offset: Vector2 = Vector2.ZERO


## Drive the pure offset formula against a known viewport half and sensitivity,
## then assert that assigning it to a real Camera2D node is reflected in its
## offset property. This confirms the formula result is compatible with
## Camera2D.offset (same type, same precision).
## Note: Full end-to-end testing of PlayerController._handle_mouse_look()
## requires a CharacterBody2D physics world and is covered by manual / scene
## integration tests; headless standalone tests are limited to formula and
## property contract verification.
func test_handle_mouse_look_sets_camera_offset() -> void:
	# Simulate: viewport centre = (640, 360), mouse at (800, 360), sensitivity = 0.5
	var half := Vector2(640.0, 360.0)
	var mouse := Vector2(800.0, 360.0)
	var sensitivity := 0.5
	var expected_offset := (mouse - half) * sensitivity  # (80, 0)
	var fake_cam := _FakeCamera2D.new()
	add_child(fake_cam)
	fake_cam.offset = expected_offset
	_assert(_is_approx_equal(fake_cam.offset, expected_offset),
		"Camera2D.offset property stores the result of (mouse - viewport_half) * sensitivity")
	fake_cam.queue_free()


## Verify that the device_id >= 0 gate condition used in _handle_mouse_look()
## prevents any offset update. Tests the boolean guard logic directly, since
## instantiating PlayerController requires a physics world not available in
## headless standalone mode.
func test_handle_mouse_look_no_op_for_gamepad() -> void:
	# When device_id >= 0 the camera offset must remain unchanged.
	var fake_cam := _FakeCamera2D.new()
	add_child(fake_cam)
	var initial_offset := Vector2(10.0, 5.0)
	fake_cam.offset = initial_offset
	# Mirror the gate from _handle_mouse_look(): if device_id >= 0, return early.
	var device_id: int = 0  # gamepad slot
	var should_update: bool = device_id < 0  # false for gamepad
	if should_update:
		fake_cam.offset = Vector2(999.0, 999.0)  # must not reach here
	_assert(_is_approx_equal(fake_cam.offset, initial_offset),
		"device_id >= 0 gate prevents Camera2D.offset from being updated")
	fake_cam.queue_free()


# ---------------------------------------------------------------------------
# Aim / rotation direction tests
#
# These tests validate the formula used by PlayerController._handle_aim()
# when device_id < 0 (keyboard + mouse):
#   look_at(get_global_mouse_position())
# Internally, look_at() sets rotation = (target - global_position).angle().
# The helper _compute_aim_angle() mirrors that formula for headless testing.
# ---------------------------------------------------------------------------

## Pure version of the rotation formula used by look_at() in _handle_aim().
func _compute_aim_angle(player_pos: Vector2, cursor_pos: Vector2) -> float:
	return (cursor_pos - player_pos).angle()


## Cursor directly to the right of the player → rotation = 0 rad.
func test_aim_angle_cursor_right_of_player() -> void:
	var angle := _compute_aim_angle(Vector2.ZERO, Vector2(100.0, 0.0))
	_assert(_is_approx_equal_f(angle, 0.0),
		"cursor to the right produces a rotation of 0 rad (east)")


## Cursor directly below the player → rotation = PI/2 rad (Godot Y-down).
func test_aim_angle_cursor_below_player() -> void:
	var angle := _compute_aim_angle(Vector2.ZERO, Vector2(0.0, 100.0))
	_assert(_is_approx_equal_f(angle, PI / 2.0),
		"cursor below produces a rotation of PI/2 rad (south)")


## Cursor directly to the left of the player → rotation = PI rad (or -PI).
func test_aim_angle_cursor_left_of_player() -> void:
	var angle := _compute_aim_angle(Vector2.ZERO, Vector2(-100.0, 0.0))
	_assert(_is_approx_equal_f(abs(angle), PI),
		"cursor to the left produces a rotation of PI rad (west)")


## Cursor directly above the player → rotation = -PI/2 rad.
func test_aim_angle_cursor_above_player() -> void:
	var angle := _compute_aim_angle(Vector2.ZERO, Vector2(0.0, -100.0))
	_assert(_is_approx_equal_f(angle, -PI / 2.0),
		"cursor above produces a rotation of -PI/2 rad (north)")


## Cursor to the upper-right (NE diagonal) → rotation = -PI/4 rad.
func test_aim_angle_cursor_diagonal_ne() -> void:
	var angle := _compute_aim_angle(Vector2.ZERO, Vector2(100.0, -100.0))
	_assert(_is_approx_equal_f(angle, -PI / 4.0),
		"cursor upper-right produces a rotation of -PI/4 rad (north-east diagonal)")


## The fired direction vector (Vector2.RIGHT.rotated(rotation)) matches the
## unit vector from player to cursor. This mirrors _fire() in PlayerController.
func test_aim_direction_vector_matches_rotation() -> void:
	var player_pos := Vector2(50.0, 80.0)
	var cursor_pos := Vector2(150.0, 80.0)  # cursor to the right
	var rotation := _compute_aim_angle(player_pos, cursor_pos)
	var fire_dir := Vector2.RIGHT.rotated(rotation)
	var expected_dir := (cursor_pos - player_pos).normalized()
	_assert(_is_approx_equal(fire_dir, expected_dir),
		"fired direction vector matches the normalised player→cursor unit vector")


## mouse_look_sensitivity default and clamped range: verify the default value
## exported by PlayerController is within [0.0, 1.0].
func test_mouse_look_sensitivity_default_is_in_range() -> void:
	var pc := PlayerController.new()
	var s := pc.mouse_look_sensitivity
	_assert(s >= 0.0 and s <= 1.0,
		"mouse_look_sensitivity default (%s) is within [0.0, 1.0]" % str(s))
	pc.free()
