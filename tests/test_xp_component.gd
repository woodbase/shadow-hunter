## Unit tests for XPComponent.
##
## Designed to run as a standalone scene script (attach to a Node in a test scene)
## or through a GUT (Godot Unit Testing) test runner.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("XPComponent tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_initial_state()
	test_add_xp_accumulates()
	test_negative_xp_is_ignored()
	test_zero_xp_is_ignored()
	test_xp_changed_signal_emitted()
	test_level_up_on_threshold()
	test_xp_resets_after_level_up()
	test_leveled_up_signal_carries_new_level()
	test_multiple_level_ups_in_one_add()
	test_xp_for_next_level_scales_with_level()
	test_level_does_not_decrease()
	test_xp_changed_signal_after_level_up_reflects_new_threshold()


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


func _make_xp(base: int = 100) -> XPComponent:
	var xp := XPComponent.new()
	xp.base_xp = base
	add_child(xp)
	return xp


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_initial_state() -> void:
	var xp := _make_xp()
	_assert(xp.level == 1, "initial level is 1")
	_assert(xp.current_xp == 0, "initial current_xp is 0")


func test_add_xp_accumulates() -> void:
	var xp := _make_xp()
	xp.add_xp(30)
	xp.add_xp(20)
	_assert(xp.current_xp == 50, "XP accumulates across multiple add_xp calls")


func test_negative_xp_is_ignored() -> void:
	var xp := _make_xp()
	xp.add_xp(-50)
	_assert(xp.current_xp == 0, "negative XP amount is ignored")
	_assert(xp.level == 1, "level unchanged after negative XP")


func test_zero_xp_is_ignored() -> void:
	var xp := _make_xp()
	xp.add_xp(0)
	_assert(xp.current_xp == 0, "zero XP amount is ignored")


func test_xp_changed_signal_emitted() -> void:
	var xp := _make_xp()
	var emitted := false
	xp.xp_changed.connect(func(_c: int, _n: int) -> void: emitted = true)
	xp.add_xp(10)
	_assert(emitted, "xp_changed signal emitted after add_xp")


func test_level_up_on_threshold() -> void:
	var xp := _make_xp(100)
	xp.add_xp(100)  # Exactly meets level 1→2 threshold (base_xp * 1 = 100)
	_assert(xp.level == 2, "level increases when XP threshold is reached")


func test_xp_resets_after_level_up() -> void:
	var xp := _make_xp(100)
	xp.add_xp(110)  # 10 XP overflow after levelling up
	_assert(xp.current_xp == 10, "current_xp carries over remainder after level-up")


func test_leveled_up_signal_carries_new_level() -> void:
	var xp := _make_xp(100)
	var received_level: int = 0
	xp.leveled_up.connect(func(lv: int) -> void: received_level = lv)
	xp.add_xp(100)
	_assert(received_level == 2, "leveled_up signal carries the new level")


func test_multiple_level_ups_in_one_add() -> void:
	var xp := _make_xp(100)
	# Level 1→2 costs 100; level 2→3 costs 200 → total 300 XP for two level-ups
	xp.add_xp(300)
	_assert(xp.level == 3, "multiple level-ups are processed in a single add_xp call")


func test_xp_for_next_level_scales_with_level() -> void:
	var xp := _make_xp(100)
	_assert(xp.xp_for_next_level() == 100, "level 1 threshold is base_xp * 1")
	xp.add_xp(100)  # reach level 2
	_assert(xp.xp_for_next_level() == 200, "level 2 threshold is base_xp * 2")


func test_level_does_not_decrease() -> void:
	var xp := _make_xp(100)
	xp.add_xp(100)  # reach level 2
	xp.add_xp(-50)  # negative — should be ignored
	_assert(xp.level == 2, "level does not decrease from negative XP")


func test_xp_changed_signal_after_level_up_reflects_new_threshold() -> void:
	var xp := _make_xp(100)
	var last_current: int = -1
	var last_needed: int = -1
	xp.xp_changed.connect(func(c: int, n: int) -> void:
		last_current = c
		last_needed = n
	)
	xp.add_xp(110)  # level up with 10 overflow
	_assert(last_current == 10, "xp_changed current reflects overflow after level-up")
	_assert(last_needed == 200, "xp_changed needed reflects new level threshold after level-up")
