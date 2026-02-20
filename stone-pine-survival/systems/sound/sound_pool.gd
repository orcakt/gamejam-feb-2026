class_name SoundPool
extends Node

const MAX_POOL_SIZE := 8

var _free_players: Array[AudioStreamPlayer] = []
var _free_players_2d: Array[AudioStreamPlayer2D] = []
var _all_players: Array[AudioStreamPlayer] = []
var _all_players_2d: Array[AudioStreamPlayer2D] = []
var _stream_cache: Dictionary = {}  # String -> AudioStream


## Play a non-spatial sound. Returns the player used.
func play(path: String, pitch: float = 1.0) -> AudioStreamPlayer:
	var stream := _load_stream(path)
	if stream == null:
		return null
	var player := _acquire_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()
	return player


## Play a sound at a world-space position (AudioStreamPlayer2D).
func play_2d(path: String, world_pos: Vector2, pitch: float = 1.0) -> AudioStreamPlayer2D:
	var stream := _load_stream(path)
	if stream == null:
		return null
	var player := _acquire_player_2d()
	player.stream = stream
	player.pitch_scale = pitch
	player.global_position = world_pos
	player.play()
	return player


# Non-spatial pool

func _acquire_player() -> AudioStreamPlayer:
	if not _free_players.is_empty():
		return _free_players.pop_back()
	if _all_players.size() < MAX_POOL_SIZE:
		return _create_player()
	# Pool full: stop oldest and reuse it
	_all_players[0].stop()
	return _all_players[0]


func _create_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	_all_players.append(p)
	p.finished.connect(_on_player_finished.bind(p))
	return p


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player not in _free_players:
		_free_players.append(player)


#  Spatial 2D pool

func _acquire_player_2d() -> AudioStreamPlayer2D:
	if not _free_players_2d.is_empty():
		return _free_players_2d.pop_back()
	if _all_players_2d.size() < MAX_POOL_SIZE:
		return _create_player_2d()
	_all_players_2d[0].stop()
	return _all_players_2d[0]


func _create_player_2d() -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	add_child(p)
	_all_players_2d.append(p)
	p.finished.connect(_on_player_2d_finished.bind(p))
	return p


func _on_player_2d_finished(player: AudioStreamPlayer2D) -> void:
	if player not in _free_players_2d:
		_free_players_2d.append(player)


# Stream cache

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		push_warning("SoundPool: resource not found: " + path)
		return null
	var stream := ResourceLoader.load(path) as AudioStream
	if stream == null:
		push_warning("SoundPool: failed to cast as AudioStream: " + path)
		return null
	_stream_cache[path] = stream
	return stream
