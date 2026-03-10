## WaveData — Resource that describes a single wave's composition.
##
## Assign an array of WaveData resources to [WaveSpawner] for fully data-driven wave design.
##
## After a wave is cleared the level controller writes telemetry back into the fields below
## ([member clear_time_sec], [member damage_taken], [member kills_per_minute]) so that
## the data is accessible for inspection and future tuning.
class_name WaveData
extends Resource

@export var wave_name: String = "Wave 1"
@export var enemy_count: int = 5
@export var spawn_delay: float = 0.3

@export var enemy_scene: PackedScene
@export var enemy_scene_pool: Array[PackedScene] = []
## Encounter identity controls pacing and composition behaviors in WaveSpawner.
@export_enum("standard", "rush", "attrition", "burst") var wave_identity: StringName = "standard"

## Runtime telemetry — populated by the level controller after this wave is cleared.
## These values are per-run and are NOT persisted back to disk.
var clear_time_sec: float = 0.0
var damage_taken: float = 0.0
var kills_per_minute: float = 0.0
