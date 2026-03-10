## LightSystem — updates enemy visibility based on distance from the player.
##
## Place this node in the scene tree. It locates the player via the "player"
## group and evaluates every node in the "enemies" group at a configurable
## interval, hiding enemies outside [member light_radius] and revealing those
## within it.
##
## The radius and update cadence are both configurable via exported properties.
class_name LightSystem
extends Node

## Radius of the player's lantern in world units.
## Enemies beyond this distance are hidden; those within it are visible.
@export var light_radius: float = 250.0

## How often (in seconds) visibility is recalculated.
## Lower values are more responsive; higher values reduce per-frame overhead
## when many enemies are present. At the default of 0.05 s the system runs at
## 20 Hz, which is imperceptible for a shadow-reveal mechanic.
@export_range(0.0, 0.5, 0.01) var update_interval: float = 0.05

var _time_since_update: float = 0.0


func _physics_process(delta: float) -> void:
	_time_since_update += delta
	if _time_since_update < update_interval:
		return
	_time_since_update = 0.0
	_update_visibility()


## Evaluate every enemy's distance to the player and update visibility.
func _update_visibility() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue
		var in_light: bool = (
			player.global_position.distance_to(enemy_node.global_position) <= light_radius
		)
		if enemy_node.has_method("set_in_light"):
			enemy_node.set_in_light(in_light)
