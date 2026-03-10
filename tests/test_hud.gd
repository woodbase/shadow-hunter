## Unit tests for HUD wave-progress clarity.
##
## Validates wave label formatting, wave banner text, and wave summary banner
## without requiring the full game scene.  Run standalone: attach to a Node root.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("HUD tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_wave_label_shows_current_and_total()
	test_wave_label_shows_padded_numbers()
	test_wave_label_no_total_omits_denominator()
	test_set_total_waves_updates_label()
	test_set_wave_clamps_below_one()
	test_set_total_waves_zero_omits_denominator()
	test_set_score_updates_label()
	test_show_wave_banner_sets_label_and_shows_banner()
	test_show_wave_banner_includes_total_waves()
	test_show_wave_summary_text_format()
	test_show_wave_summary_shows_banner()
	test_show_final_results_shows_panel()
	test_show_final_results_hides_wave_banner()
	test_show_final_results_hides_wave_summary_banner()
	test_show_final_results_score_text()
	test_show_final_results_wave_text_with_total()
	test_show_final_results_wave_text_without_total()


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


func _make_hud() -> HUD:
	var scene: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud := scene.instantiate() as HUD
	add_child(hud)
	return hud


# ---------------------------------------------------------------------------
# Wave label formatting
# ---------------------------------------------------------------------------

func test_wave_label_shows_current_and_total() -> void:
	var hud := _make_hud()
	hud.set_wave(2, 5)
	_assert(hud.wave_label.text == "Wave 02 / 05", "wave label shows current / total")


func test_wave_label_shows_padded_numbers() -> void:
	var hud := _make_hud()
	hud.set_wave(1, 10)
	_assert(hud.wave_label.text == "Wave 01 / 10", "wave label zero-pads current wave")


func test_wave_label_no_total_omits_denominator() -> void:
	var hud := _make_hud()
	hud.set_wave(3)
	_assert(hud.wave_label.text == "Wave 03", "wave label omits denominator when total is unknown")


func test_set_total_waves_updates_label() -> void:
	var hud := _make_hud()
	hud.set_wave(1)
	hud.set_total_waves(4)
	_assert(hud.wave_label.text == "Wave 01 / 04", "set_total_waves causes label to show denominator")


func test_set_wave_clamps_below_one() -> void:
	var hud := _make_hud()
	hud.set_wave(0, 5)
	_assert(hud.wave_label.text == "Wave 01 / 05", "set_wave clamps wave number to minimum 1")


func test_set_total_waves_zero_omits_denominator() -> void:
	var hud := _make_hud()
	hud.set_total_waves(0)
	hud.set_wave(2)
	_assert(hud.wave_label.text == "Wave 02", "total_waves=0 omits denominator")


# ---------------------------------------------------------------------------
# Score label
# ---------------------------------------------------------------------------

func test_set_score_updates_label() -> void:
	var hud := _make_hud()
	hud.set_score(1500)
	_assert(hud.score_label.text == "Score: 1500", "set_score updates score label text")


# ---------------------------------------------------------------------------
# Wave banner
# ---------------------------------------------------------------------------

func test_show_wave_banner_sets_label_and_shows_banner() -> void:
	var hud := _make_hud()
	hud.show_wave_banner(3, 5)
	_assert(hud.wave_banner.visible, "show_wave_banner makes banner visible")


func test_show_wave_banner_includes_total_waves() -> void:
	var hud := _make_hud()
	hud.show_wave_banner(2, 5)
	# Banner text mirrors the wave label which shows the formatted "Wave 02 / 05"
	_assert(hud.wave_banner.text == "Wave 02 / 05",
		"wave banner text includes current and total waves")


# ---------------------------------------------------------------------------
# Wave summary banner
# ---------------------------------------------------------------------------

func test_show_wave_summary_text_format() -> void:
	var hud := _make_hud()
	hud.show_wave_summary(2, 750)
	_assert(hud.wave_summary_banner.text == "Wave 2 cleared — Score 750",
		"wave summary banner text shows wave number and score")


func test_show_wave_summary_shows_banner() -> void:
	var hud := _make_hud()
	hud.show_wave_summary(1, 350)
	_assert(hud.wave_summary_banner.visible, "show_wave_summary makes summary banner visible")


# ---------------------------------------------------------------------------
# Final results panel
# ---------------------------------------------------------------------------

func test_show_final_results_shows_panel() -> void:
	var hud := _make_hud()
	hud.show_final_results(1200, 3)
	_assert(hud.game_over_panel.visible, "show_final_results makes game-over panel visible")


func test_show_final_results_hides_wave_banner() -> void:
	var hud := _make_hud()
	hud.show_wave_banner(2, 3)
	hud.show_final_results(800, 2)
	_assert(not hud.wave_banner.visible, "show_final_results hides wave banner")


func test_show_final_results_hides_wave_summary_banner() -> void:
	var hud := _make_hud()
	hud.show_wave_summary(1, 100)
	hud.show_final_results(800, 2)
	_assert(not hud.wave_summary_banner.visible, "show_final_results hides wave summary banner")


func test_show_final_results_score_text() -> void:
	var hud := _make_hud()
	hud.show_final_results(2050, 4)
	_assert(hud.final_score_label.text == "Score: 2050",
		"final score label shows correct score")


func test_show_final_results_wave_text_with_total() -> void:
	var hud := _make_hud()
	hud.set_total_waves(5)
	hud.show_final_results(1000, 3)
	_assert(hud.final_wave_label.text == "Final Wave: 3 / 5",
		"final wave label shows wave / total when total is known")


func test_show_final_results_wave_text_without_total() -> void:
	var hud := _make_hud()
	hud.show_final_results(500, 2)
	_assert(hud.final_wave_label.text == "Final Wave: 2",
		"final wave label omits denominator when total waves is unknown")
