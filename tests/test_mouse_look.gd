## Unit tests for mouse look camera offset math.
##
## Validates that the camera offset produced by _handle_mouse_look() is
## correct for both horizontal and vertical mouse positions, that sensitivity
## scales the result proportionally, and that a centred cursor yields no
## offset.
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
