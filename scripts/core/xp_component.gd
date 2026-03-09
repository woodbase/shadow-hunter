## XPComponent — tracks player XP and handles level-up logic.
##
## Add as a child node of [PlayerController]. Call [method add_xp] to grant XP.
## Connect to [signal leveled_up] to respond to level increases.
## Each level requires [member base_xp] * current_level XP to advance.
class_name XPComponent
extends Node

## Emitted when the player's XP total changes.
## [param current_xp] is the progress within the current level;
## [param xp_needed] is the threshold required to reach the next level.
signal xp_changed(current_xp: int, xp_needed: int)

## Emitted when the player gains a level.
signal leveled_up(new_level: int)

## XP required to go from level 1 to level 2. Each subsequent level multiplies
## by the current level, so level N→N+1 costs base_xp * N.
@export var base_xp: int = 100

## Current player level (starts at 1).
var level: int = 1

## XP accumulated within the current level.
var current_xp: int = 0


## Returns the XP required to advance from the current [member level] to the next.
func xp_for_next_level() -> int:
	return base_xp * level


## Add [param amount] XP and process any resulting level-ups.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount
	_check_level_up()
	xp_changed.emit(current_xp, xp_for_next_level())


func _check_level_up() -> void:
	var needed := xp_for_next_level()
	while current_xp >= needed:
		current_xp -= needed
		level += 1
		leveled_up.emit(level)
		needed = xp_for_next_level()
