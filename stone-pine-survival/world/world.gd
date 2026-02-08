extends Node2D

# Preload player scene for spawning
const PLAYER_SCENE = preload("res://world/player/player.tscn")

# Track spawned players by peer_id
var players: Dictionary = {}


func _ready() -> void:
	if not multiplayer.has_multiplayer_peer():
		push_warning("No multiplayer peer found in world scene")
		return

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# local player
	_spawn_player(multiplayer.get_unique_id())


func _on_peer_connected(peer_id: int) -> void:
	# Only the server spawns players for new peers
	# Clients will receive the spawn via MultiplayerSpawner sync
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if peer_id in players:
		var player = players[peer_id]
		if is_instance_valid(player):
			player.queue_free()
		players.erase(peer_id)


func _spawn_player(peer_id: int) -> void:
	if peer_id in players:
		return

	var player = PLAYER_SCENE.instantiate()
	player.name = "Player" + str(peer_id)

	# we'll change this once we have logic for this
	player.position = _get_spawn_position(peer_id)

	# Add to scene, second parameter 'true' means force readable name
	$Players.add_child(player, true)

	# Assign multiplayer authority to the owning peer
	player.set_multiplayer_authority(peer_id)

	players[peer_id] = player

	print("Spawned player for peer %d at position %s (Authority: %d)" % [peer_id, player.position, player.get_multiplayer_authority()])


func _get_spawn_position(peer_id: int) -> Vector2:
	var base_x = 100
	var base_y = 100
	var offset = 50

	var x = base_x + ((peer_id - 1) * offset)
	var y = base_y

	return Vector2(x, y)
