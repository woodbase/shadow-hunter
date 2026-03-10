## Unit tests for XPOrb.
##
## Designed to run as a standalone scene script (attach to a Node in a test scene)
## or through a GUT (Godot Unit Testing) test runner.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0

const XP_ORB_SCENE_PATH: String = "res://scenes/player/xp_orb.tscn"


func _ready() -> void:
	_run_all()
	print("XPOrb tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_default_xp_amount()
	test_xp_amount_is_configurable()
	test_player_receives_xp_on_body_entered()
	test_player_receives_correct_amount()
	test_non_player_body_does_not_grant_xp()
	test_player_group_without_add_xp_is_safely_ignored()


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


## Minimal player stand-in: added to the "player" group and tracks XP received.
class PlayerStub extends Node2D:
	var xp_received: int = 0

	func _ready() -> void:
		add_to_group("player")

	func add_xp(amount: int) -> void:
		xp_received += amount


func _make_orb(amount: int = 10) -> XPOrb:
	var scene: PackedScene = load(XP_ORB_SCENE_PATH)
	var orb := scene.instantiate() as XPOrb
	orb.xp_amount = amount
	add_child(orb)
	return orb


func _make_player_stub() -> PlayerStub:
	var stub := PlayerStub.new()
	add_child(stub)
	return stub


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_default_xp_amount() -> void:
	var orb := _make_orb()
	_assert(orb.xp_amount == 10, "default xp_amount is 10")


func test_xp_amount_is_configurable() -> void:
	var orb := _make_orb(25)
	_assert(orb.xp_amount == 25, "xp_amount reflects assigned value")


func test_player_receives_xp_on_body_entered() -> void:
	var orb := _make_orb(20)
	var player := _make_player_stub()
	orb._on_body_entered(player)
	_assert(player.xp_received > 0, "player receives XP when orb's body_entered fires")


func test_player_receives_correct_amount() -> void:
	var orb := _make_orb(35)
	var player := _make_player_stub()
	orb._on_body_entered(player)
	_assert(player.xp_received == 35, "player receives exactly xp_amount XP on collection")


func test_non_player_body_does_not_grant_xp() -> void:
	var orb := _make_orb(20)
	var player := _make_player_stub()
	var other := Node2D.new()
	add_child(other)
	orb._on_body_entered(other)
	_assert(player.xp_received == 0, "non-player body entering orb does not grant XP")


func test_player_group_without_add_xp_is_safely_ignored() -> void:
	var orb := _make_orb(20)
	var player := _make_player_stub()
	var fake_player := Node2D.new()
	fake_player.add_to_group("player")
	add_child(fake_player)
	orb._on_body_entered(fake_player)
	_assert(player.xp_received == 0, "player-group node without add_xp does not grant XP")
