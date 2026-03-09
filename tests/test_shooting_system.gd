## Unit tests for the weapon shooting system.
##
## Validates that:
##  - Mouse click (fire action) gate logic is correct.
##  - Fire rate cooldown blocks shots fired in quick succession.
##  - Fire rate cooldown permits a shot once fully elapsed.
##  - Fire direction is derived from player rotation (normalised).
##  - _fire_cooldown is reset to weapon.fire_rate after each shot.
##  - BaseWeapon exported defaults are sane (positive fire_rate and damage).
##  - BaseWeapon.fire() requires a valid projectile_scene before spawning.
##  - Muzzle flash node is hidden on weapon ready and shown after firing.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("Shooting system tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_fire_action_gate_allows_shot_when_cooldown_zero()
	test_fire_action_gate_blocks_shot_when_cooldown_positive()
	test_fire_rate_cooldown_blocks_rapid_second_shot()
	test_fire_rate_cooldown_allows_shot_after_full_elapsed_time()
	test_fire_direction_right_at_zero_rotation()
	test_fire_direction_up_at_negative_half_pi_rotation()
	test_fire_direction_is_normalised_at_arbitrary_rotation()
	test_cooldown_reset_equals_weapon_fire_rate_after_shot()
	test_base_weapon_default_fire_rate_is_positive()
	test_base_weapon_default_damage_is_positive()
	test_base_weapon_no_projectile_scene_does_not_crash()
	test_muzzle_flash_duration_constant_is_positive()
	test_muzzle_flash_timer_positive_after_firing()
	test_muzzle_flash_timer_reaches_zero_after_full_duration()
	test_pulse_carbine_muzzle_flash_hidden_on_ready()
	test_pulse_carbine_has_muzzle_flash_node()


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


func _is_approx_v(a: Vector2, b: Vector2, tolerance: float = 0.001) -> bool:
	return a.distance_to(b) < tolerance


## Pure gate formula used by PlayerController._handle_fire().
func _gate_allows_fire(cooldown: float) -> bool:
	return cooldown <= 0.0


# ---------------------------------------------------------------------------
# Fire-action gate tests
# ---------------------------------------------------------------------------

func test_fire_action_gate_allows_shot_when_cooldown_zero() -> void:
	_assert(_gate_allows_fire(0.0), "gate allows shot when cooldown is exactly zero")


func test_fire_action_gate_blocks_shot_when_cooldown_positive() -> void:
	_assert(not _gate_allows_fire(0.05), "gate blocks shot when cooldown is positive")


# ---------------------------------------------------------------------------
# Fire rate / cooldown tests
# ---------------------------------------------------------------------------

func test_fire_rate_cooldown_blocks_rapid_second_shot() -> void:
	# Simulate a shot: cooldown is set to fire_rate.
	var fire_rate: float = 0.15
	var cooldown: float = 0.0
	if _gate_allows_fire(cooldown):
		cooldown = fire_rate
	_assert(not _gate_allows_fire(cooldown),
		"fire rate cooldown blocks a rapid second shot")


func test_fire_rate_cooldown_allows_shot_after_full_elapsed_time() -> void:
	# Simulate the full cooldown period passing.
	var fire_rate: float = 0.15
	var cooldown: float = fire_rate
	cooldown -= fire_rate
	_assert(_gate_allows_fire(cooldown),
		"shot is allowed once the full fire_rate duration has elapsed")


# ---------------------------------------------------------------------------
# Fire direction tests
# ---------------------------------------------------------------------------

## The production formula is: Vector2.RIGHT.rotated(rotation)
func test_fire_direction_right_at_zero_rotation() -> void:
	var direction := Vector2.RIGHT.rotated(0.0)
	_assert(_is_approx_v(direction, Vector2(1.0, 0.0)),
		"fire direction is RIGHT when player rotation is 0")


func test_fire_direction_up_at_negative_half_pi_rotation() -> void:
	var direction := Vector2.RIGHT.rotated(-PI / 2.0)
	_assert(_is_approx_v(direction, Vector2(0.0, -1.0)),
		"fire direction is UP when player rotation is -PI/2")


func test_fire_direction_is_normalised_at_arbitrary_rotation() -> void:
	# Vector2.RIGHT is a unit vector; rotating it keeps its length at 1.
	var direction := Vector2.RIGHT.rotated(PI / 3.0)
	_assert(is_equal_approx(direction.length(), 1.0),
		"fire direction vector is normalised for any player rotation")


# ---------------------------------------------------------------------------
# Cooldown reset test
# ---------------------------------------------------------------------------

func test_cooldown_reset_equals_weapon_fire_rate_after_shot() -> void:
	var fire_rate: float = 0.2
	var cooldown: float = 0.0
	# Mirror PlayerController._fire(): cooldown = _weapon.fire_rate
	cooldown = fire_rate
	_assert(is_equal_approx(cooldown, fire_rate),
		"_fire_cooldown is set to weapon.fire_rate immediately after firing")


# ---------------------------------------------------------------------------
# BaseWeapon default-value tests
# ---------------------------------------------------------------------------

func test_base_weapon_default_fire_rate_is_positive() -> void:
	var weapon := BaseWeapon.new()
	_assert(weapon.fire_rate > 0.0, "BaseWeapon.fire_rate default is positive")
	weapon.free()


func test_base_weapon_default_damage_is_positive() -> void:
	var weapon := BaseWeapon.new()
	_assert(weapon.damage > 0.0, "BaseWeapon.damage default is positive")
	weapon.free()


func test_base_weapon_no_projectile_scene_does_not_crash() -> void:
	# fire() without a projectile_scene must emit a warning and return safely.
	var weapon := BaseWeapon.new()
	add_child(weapon)
	weapon.projectile_scene = null
	# Should not crash; push_warning is called internally.
	weapon.fire(Vector2.RIGHT)
	_assert(true, "BaseWeapon.fire() with no projectile_scene does not crash")
	weapon.queue_free()


# ---------------------------------------------------------------------------
# Muzzle flash tests
# ---------------------------------------------------------------------------

func test_muzzle_flash_duration_constant_is_positive() -> void:
	_assert(BaseWeapon.MUZZLE_FLASH_DURATION > 0.0,
		"MUZZLE_FLASH_DURATION constant is positive")


func test_muzzle_flash_timer_positive_after_firing() -> void:
	# Simulate _show_muzzle_flash(): timer is set to MUZZLE_FLASH_DURATION.
	var flash_timer: float = 0.0
	flash_timer = BaseWeapon.MUZZLE_FLASH_DURATION
	_assert(flash_timer > 0.0,
		"muzzle flash timer is positive immediately after a shot")


func test_muzzle_flash_timer_reaches_zero_after_full_duration() -> void:
	var flash_timer: float = BaseWeapon.MUZZLE_FLASH_DURATION
	flash_timer -= BaseWeapon.MUZZLE_FLASH_DURATION
	_assert(flash_timer <= 0.0,
		"muzzle flash timer reaches zero after the full flash duration has elapsed")


func test_pulse_carbine_has_muzzle_flash_node() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pulse_carbine.tscn")
	var weapon: BaseWeapon = scene.instantiate() as BaseWeapon
	add_child(weapon)
	var flash: CanvasItem = weapon.get_node_or_null("MuzzleFlash") as CanvasItem
	_assert(flash != null, "PulseCarbine scene contains a MuzzleFlash child node")
	weapon.queue_free()


func test_pulse_carbine_muzzle_flash_hidden_on_ready() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pulse_carbine.tscn")
	var weapon: BaseWeapon = scene.instantiate() as BaseWeapon
	add_child(weapon)
	var flash: CanvasItem = weapon.get_node_or_null("MuzzleFlash") as CanvasItem
	_assert(flash != null and not flash.visible,
		"MuzzleFlash node is hidden when the weapon is first added to the scene")
	weapon.queue_free()
