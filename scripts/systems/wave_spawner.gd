## WaveSpawner — spawns waves of enemies at registered spawn points.
##
## Call [method start] with a target [Node2D] (typically the player) to begin.
## Enemies are given the target reference automatically.
## Connect to [signal wave_started], [signal wave_completed], and [signal all_waves_completed]
## to drive level progression and UI feedback.
##
## Difficulty scaling: set [member health_scale_per_wave], [member speed_scale_per_wave],
## [member damage_scale_per_wave], and [member count_scale_per_wave] to grow enemy
## strength progressively. All multipliers compound as [code]1.0 + wave_index * scale[/code].
class_name WaveSpawner
extends Node

## Emitted at the start of each wave. [param wave_number] is 1-based.
signal wave_started(wave_number: int)

## Emitted when every enemy in a wave has been defeated.
signal wave_completed(wave_number: int)

## Emitted after the final wave is cleared.
signal all_waves_completed
signal enemy_spawned(enemy: EnemyBase)
signal enemy_killed

@export var enemy_scene: PackedScene
@export var total_waves: int = 3
@export var enemies_per_wave: int = 5
@export var spawn_delay: float = 0.3
@export var between_wave_delay: float = 2.0
@export var wave_data_list: Array[WaveData] = []
@export var min_spawn_distance_from_player: float = 220.0
@export var spawn_retry_count: int = 8

## Fraction by which enemy max-health grows per wave (e.g. 0.12 = +12 % per wave).
## Multiplier is [code]1.0 + wave_index * health_scale_per_wave[/code].
@export var health_scale_per_wave: float = 0.12
## Fraction by which enemy move speed grows per wave (e.g. 0.08 = +8 % per wave).
## Multiplier is [code]1.0 + wave_index * speed_scale_per_wave[/code].
@export var speed_scale_per_wave: float = 0.08
## Fraction by which enemy attack damage grows per wave (e.g. 0.08 = +8 % per wave).
## Multiplier is [code]1.0 + wave_index * damage_scale_per_wave[/code].
@export var damage_scale_per_wave: float = 0.08
## Fraction by which procedural enemy count grows per wave (e.g. 0.20 = +20 % per wave).
## Has no effect when [member wave_data_list] is set.
## Multiplier is [code]1.0 + wave_index * count_scale_per_wave[/code].
@export var count_scale_per_wave: float = 0.20

const IDENTITY_STANDARD: StringName = "standard"
const IDENTITY_RUSH: StringName = "rush"
const IDENTITY_ATTRITION: StringName = "attrition"
const IDENTITY_BURST: StringName = "burst"
const BURST_GROUP_SIZE: int = 3

## Set by the owning level. Also accepted via [method start].
var spawn_points: Array[Node2D] = []

var _current_wave: int = 0
var _active_enemies: int = 0
var _player: Node2D = null
var _players: Array[Node2D] = []
var _between_waves: bool = false
var _spawning: bool = false
var _transitioning: bool = false
var _starting_wave: bool = false
var _wave_in_progress: bool = false


## Returns true while a wave transition is in progress (between-wave delay).
func is_transitioning() -> bool:
	return _transitioning


## Begin spawning waves, targeting [param player].
func start(player: Node2D) -> void:
	_player = player
	_players = [player]
	_current_wave = 0
	_transitioning = false
	_between_waves = false
	_active_enemies = 0
	_starting_wave = false
	_wave_in_progress = false
	_start_wave(_current_wave)


## Register an additional co-op player as an enemy target.
## Call after [method start] for each extra player (players 2–4).
func add_coop_player(player: Node2D) -> void:
	if not _players.has(player):
		_players.append(player)


func _start_wave(index: int) -> void:
	if _starting_wave:
		return
	_starting_wave = true
	if index >= _get_total_waves():
		all_waves_completed.emit()
		_starting_wave = false
		return

	# Guard against double-triggering wave starts
	if _wave_in_progress:
		_starting_wave = false
		return

	_wave_in_progress = true
	wave_started.emit(index + 1)
	_active_enemies = _get_wave_enemy_count(index)
	_starting_wave = false
	_spawn_wave_enemies()


func _spawn_wave_enemies() -> void:
	var wave_data: WaveData = _get_wave_data(_current_wave)
	var identity: StringName = _get_wave_identity(wave_data)
	match identity:
		IDENTITY_RUSH:
			await _spawn_rush_wave()
		IDENTITY_ATTRITION:
			await _spawn_attrition_wave()
		IDENTITY_BURST:
			await _spawn_burst_wave()
		_:
			await _spawn_standard_wave()


func _spawn_standard_wave() -> void:
	var wave_spawn_delay: float = _get_wave_spawn_delay(_current_wave)
	for i: int in _active_enemies:
		if i > 0:
			await get_tree().create_timer(wave_spawn_delay).timeout
		_spawn_single_enemy()


func _spawn_rush_wave() -> void:
	var base_delay: float = _get_wave_spawn_delay(_current_wave)
	var rush_delay: float = maxf(0.05, base_delay * 0.5)
	for i: int in _active_enemies:
		if i > 0:
			# Front-load spawns to hit the player quickly, then taper to base pacing.
			var delay: float = i < 4 ? rush_delay * 0.5 : rush_delay
			await get_tree().create_timer(delay).timeout
		_spawn_single_enemy()


func _spawn_attrition_wave() -> void:
	var base_delay: float = _get_wave_spawn_delay(_current_wave)
	for i: int in _active_enemies:
		if i > 0:
			# Add jitter to keep pressure steady but not uniform.
			var variance: float = randf_range(-0.10, 0.30)
			var delay: float = maxf(0.1, base_delay * (1.2 + variance))
			await get_tree().create_timer(delay).timeout
		_spawn_single_enemy()


func _spawn_burst_wave() -> void:
	var base_delay: float = _get_wave_spawn_delay(_current_wave)
	var intra_burst_delay: float = maxf(0.05, base_delay * 0.35)
	var burst_pause: float = maxf(base_delay * 2.2, 0.6)
	var spawned: int = 0
	while spawned < _active_enemies:
		for i: int in BURST_GROUP_SIZE:
			if spawned >= _active_enemies:
				break
			if i > 0:
				await get_tree().create_timer(intra_burst_delay).timeout
			_spawn_single_enemy()
			spawned += 1
		if spawned < _active_enemies:
			await get_tree().create_timer(burst_pause).timeout


func _spawn_single_enemy() -> void:
	if spawn_points.is_empty():
		push_warning("WaveSpawner: no spawn_points assigned.")
		_on_enemy_removed(false)
		return

	var selected_enemy_scene: PackedScene = _get_wave_enemy_scene(_current_wave)
	if selected_enemy_scene == null:
		push_warning("WaveSpawner: no enemy scene configured for current wave.")
		_on_enemy_removed(false)
		return

	var point: Node2D = _select_spawn_point()
	if point == null:
		push_warning("WaveSpawner: failed to find valid spawn point outside safety radius.")
		_on_enemy_removed(false)
		return
	var enemy: EnemyBase = selected_enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_warning("WaveSpawner: selected enemy scene root is not an EnemyBase.")
		_on_enemy_removed(false)
		return

	var active_players: Array[Node2D] = _get_active_players()
	enemy.global_position = _get_safe_spawn_position(point.global_position, active_players)
	# Apply wave-based difficulty scaling. move_speed and damage are guaranteed
	# @export properties of EnemyBase (null was already rejected above).
	enemy.move_speed *= _get_difficulty_multiplier(speed_scale_per_wave, _current_wave)
	enemy.damage *= _get_difficulty_multiplier(damage_scale_per_wave, _current_wave)
	if not active_players.is_empty():
		enemy.set_target(active_players[randi() % active_players.size()])
	elif _player != null:
		enemy.set_target(_player)
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)
	# Scale enemy HP for co-op difficulty.
	# add_child() triggers _ready() on the enemy, so HealthComponent is initialized here.
	var health: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var hp_multiplier: float = CoopManager.get_enemy_health_multiplier() * _get_difficulty_multiplier(health_scale_per_wave, _current_wave)
		if not is_equal_approx(hp_multiplier, 1.0):
			health.max_health *= hp_multiplier
			health.current_health = health.max_health
			health.health_changed.emit(health.current_health, health.max_health)
	enemy_spawned.emit(enemy)


func _on_enemy_died() -> void:
	_on_enemy_removed(true)


func _on_enemy_removed(killed: bool) -> void:
	_active_enemies -= 1
	if killed:
		enemy_killed.emit()
	if _active_enemies > 0 or _between_waves:
		return

	_transitioning = true
	_between_waves = true
	_wave_in_progress = false
	wave_completed.emit(_current_wave + 1)
	_current_wave += 1
	await get_tree().create_timer(between_wave_delay).timeout
	_transitioning = false
	_between_waves = false
	_start_wave(_current_wave)


func _get_total_waves() -> int:
	if not wave_data_list.is_empty():
		return wave_data_list.size()
	return total_waves


## Returns the total number of waves for this run (public accessor).
## Get the actual number of waves that will be spawned.
## Returns the size of wave_data_list if configured, otherwise total_waves.
func get_total_waves() -> int:
	return _get_total_waves()


func _get_wave_enemy_count(index: int) -> int:
	var base_count: int = 0
	if index < wave_data_list.size():
		base_count = maxi(0, wave_data_list[index].enemy_count)
	elif not wave_data_list.is_empty():
		push_warning("WaveSpawner: missing WaveData for index %d; defaulting enemy_count=0." % index)
	else:
		base_count = roundi(enemies_per_wave * _get_difficulty_multiplier(count_scale_per_wave, index))
	return roundi(base_count * CoopManager.get_enemy_count_multiplier())


func _get_wave_spawn_delay(index: int) -> float:
	if index < wave_data_list.size():
		return maxf(0.0, wave_data_list[index].spawn_delay)
	return spawn_delay


func _get_wave_enemy_scene(index: int) -> PackedScene:
	if index < wave_data_list.size():
		var wave_data: WaveData = wave_data_list[index]
		var pool_scene: PackedScene = _pick_enemy_scene_from_pool(wave_data)
		if pool_scene != null:
			return pool_scene
		var data_enemy_scene: PackedScene = wave_data.enemy_scene
		if data_enemy_scene != null:
			return data_enemy_scene
	return enemy_scene


func _pick_enemy_scene_from_pool(wave_data: WaveData) -> PackedScene:
	if wave_data.enemy_scene_pool.is_empty():
		return null
	var valid_scenes: Array[PackedScene] = []
	for scene: PackedScene in wave_data.enemy_scene_pool:
		if scene != null:
			valid_scenes.append(scene)
	if valid_scenes.is_empty():
		return null
	return valid_scenes[randi() % valid_scenes.size()]


## Returns players that are still valid and alive — used for targeting and spawn placement.
func _get_active_players() -> Array[Node2D]:
	return _players.filter(func(p: Node2D) -> bool:
		if not is_instance_valid(p):
			return false
		var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
		return hc == null or hc.is_alive()
	)


func _get_wave_data(index: int) -> WaveData:
	if index < wave_data_list.size():
		return wave_data_list[index]
	return null


func _get_wave_identity(wave_data: WaveData) -> StringName:
	if wave_data != null and not String(wave_data.wave_identity).is_empty():
		return wave_data.wave_identity
	return IDENTITY_STANDARD


func _select_spawn_point() -> Node2D:
	if spawn_points.is_empty():
		return null
	var active_players: Array[Node2D] = _get_active_players()
	if active_players.is_empty():
		return spawn_points[randi() % spawn_points.size()]

	var farthest: Node2D = null
	var farthest_distance: float = -INF
	for _attempt: int in spawn_retry_count:
		var candidate: Node2D = spawn_points[randi() % spawn_points.size()]
		var distance: float = _distance_to_closest_player(candidate.global_position, active_players)
		if distance > farthest_distance:
			farthest_distance = distance
			farthest = candidate
		if distance >= min_spawn_distance_from_player:
			return candidate

	for candidate: Node2D in spawn_points:
		var distance: float = _distance_to_closest_player(candidate.global_position, active_players)
		if distance > farthest_distance:
			farthest_distance = distance
			farthest = candidate
		if distance >= min_spawn_distance_from_player:
			return candidate
	return farthest


func _get_safe_spawn_position(pos: Vector2, active_players: Array[Node2D]) -> Vector2:
	if active_players.is_empty():
		return pos
	var safe_pos: Vector2 = pos
	for p: Node2D in active_players:
		if not is_instance_valid(p):
			continue
		var offset: Vector2 = safe_pos - p.global_position
		var distance: float = offset.length()
		if distance < min_spawn_distance_from_player:
			var direction: Vector2 = offset.normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			safe_pos = p.global_position + direction * min_spawn_distance_from_player
	return safe_pos


func _is_far_from_all_players(pos: Vector2, active_players: Array[Node2D]) -> bool:
	for p: Node2D in active_players:
		if pos.distance_to(p.global_position) < min_spawn_distance_from_player:
			return false
	return true


func _distance_to_closest_player(pos: Vector2, active_players: Array[Node2D]) -> float:
	if active_players.is_empty():
		return INF
	var closest: float = INF
	for p: Node2D in active_players:
		closest = minf(closest, pos.distance_to(p.global_position))
	return closest


## Returns a difficulty multiplier for a given [param scale_per_wave] and [param wave_index].
## The multiplier is [code]1.0 + wave_index * scale_per_wave[/code], so the first wave always
## returns 1.0 regardless of scale.
func _get_difficulty_multiplier(scale_per_wave: float, wave_index: int) -> float:
	return 1.0 + wave_index * scale_per_wave
