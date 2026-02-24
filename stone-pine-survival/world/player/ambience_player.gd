class_name AmbiencePlayer
extends Node

const CATEGORIES: Array[String] = ["birds", "bats", "crickets", "mosquitos", "wind"]


class CategoryConfig:
	var count: int
	var interval_min: float
	var interval_max: float
	var radius: Vector2


# [env_type][category] -> CategoryConfig
var _configs: Dictionary = {}
# [category] -> float (seconds remaining)
var _timers: Dictionary = {}
var _active_zones: Array = []  # Array[EnvironmentZone]
var _sound_pool: SoundPool


func _ready() -> void:
	_sound_pool = $SoundPool
	_build_configs()
	await get_tree().process_frame
	for zone: EnvironmentZone in get_tree().get_nodes_in_group("environment_zone"):
		zone.player_entered.connect(_on_zone_entered)
		zone.player_exited.connect(_on_zone_exited)


## All environment tuning lives here.
## Each row: [count, interval_min, interval_max, radius_x, radius_y]
## count = 0 disables a category for that environment.
func _build_configs() -> void:
	var raw: Dictionary = {
		EnvironmentZone.EnvironmentType.MEADOW: {
			"birds":     [24, 15.5, 30.0, 600.0, 400.0],
			"bats":      [0,   0.0,  0.0,   0.0,   0.0],
			"crickets":  [8,   4.0, 15.0, 400.0, 400.0],
			"mosquitos": [1,   5.0, 10.0, 200.0, 200.0],
			"wind":      [3,   2.5, 10.0, 500.0, 300.0],
		},
		EnvironmentZone.EnvironmentType.FOREST: {
			"birds":     [26,  2.5, 15.0, 800.0, 800.0],
			"bats":      [1,  10.0, 20.0, 600.0, 600.0],
			"crickets":  [8,   3.0, 10.0, 400.0, 400.0],
			"mosquitos": [0,   0.0,  0.0,   0.0,   0.0],
			"wind":      [3,  6.0, 30.0, 300.0, 200.0],
		},
		EnvironmentZone.EnvironmentType.BEACH: {
			"birds":     [10, 20.0, 40.0, 600.0, 400.0],
			"bats":      [0,   0.0,  0.0,   0.0,   0.0],
			"crickets":  [0,   0.0,  0.0,   0.0,   0.0],
			"mosquitos": [0,   0.0,  0.0,   0.0,   0.0],
			"wind":      [3,   3.0,  7.0, 600.0, 400.0],
		},
		EnvironmentZone.EnvironmentType.RIVER: {
			"birds":     [15, 10.0, 20.0, 500.0, 500.0],
			"bats":      [7,  15.0, 25.0, 400.0, 400.0],
			"crickets":  [8,   6.0, 12.0, 300.0, 300.0],
			"mosquitos": [1,   3.0,  7.0, 300.0, 300.0],
			"wind":      [3,  10.0, 20.0, 400.0, 300.0],
		},
	}
	for env_type: int in raw:
		_configs[env_type] = {}
		for category: String in raw[env_type]:
			var d: Array = raw[env_type][category]
			var cfg := CategoryConfig.new()
			cfg.count = d[0]
			cfg.interval_min = d[1]
			cfg.interval_max = d[2]
			cfg.radius = Vector2(d[3], d[4])
			_configs[env_type][category] = cfg


func _process(delta: float) -> void:
	if not get_parent().is_multiplayer_authority():
		return
	var env := _get_current_environment()
	var env_configs: Dictionary = _configs.get(env, {})
	for category: String in CATEGORIES:
		var cfg: CategoryConfig = env_configs.get(category, null)
		if cfg == null or cfg.count == 0:
			_timers.erase(category)
			continue
		if not _timers.has(category):
			_timers[category] = randf_range(cfg.interval_min, cfg.interval_max)
		_timers[category] -= delta
		if _timers[category] <= 0.0:
			_play_category(category, cfg)
			_timers[category] = randf_range(cfg.interval_min, cfg.interval_max)


func _play_category(category: String, cfg: CategoryConfig) -> void:
	var file_num := randi_range(1, cfg.count)
	var path := "res://assets/sfx/ambience/%s/%d.wav" % [category, file_num]
	var offset := Vector2(
		randf_range(-cfg.radius.x, cfg.radius.x),
		randf_range(-cfg.radius.y, cfg.radius.y)
	)
	_sound_pool.play_2d(path, get_parent().global_position + offset)


func _get_current_environment() -> EnvironmentZone.EnvironmentType:
	if _active_zones.is_empty():
		return EnvironmentZone.EnvironmentType.MEADOW
	var best_zone: EnvironmentZone = _active_zones[0]
	for zone: EnvironmentZone in _active_zones:
		if zone.zone_priority > best_zone.zone_priority:
			best_zone = zone
	return best_zone.environment_type


func _on_zone_entered(zone: EnvironmentZone) -> void:
	if zone not in _active_zones:
		_active_zones.append(zone)


func _on_zone_exited(zone: EnvironmentZone) -> void:
	_active_zones.erase(zone)
