class_name World
extends Node2D

# Preload player scene for spawning
const PLAYER_SCENE = preload("res://world/player/player.tscn")

@export var spawn_point: Marker2D
@export var spawn_spacing: int = 100

@onready var crafting_ui: CraftingUI = %CraftingUI
@onready var campfire_ui: CampfireUI = %CampfireUI
@onready var inventory_ui: InventoryUI = %InventoryUI

# Track spawned players by peer_id
var players: Dictionary[int, Player]


func _ready() -> void:
	# Register terrain layers for spatial queries
	SpatialSense.register_tilemap_layers(
		$Land.get_node("TileMapLayer"),
		$Land.get_node("TileMapLayer2"),
		$Land.get_node("TileMapLayer3"),
		$Land.get_node("TileMapLayer4")
	)

	if not multiplayer.has_multiplayer_peer():
		push_warning("No multiplayer peer found in world scene")
		return

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	$PlayerSpawner.spawned.connect(_on_player_spawned)

	# Only server spawns
	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())


func _on_peer_connected(peer_id: int) -> void:
	# Only the server spawns players for new peers
	# Clients will receive the spawn via MultiplayerSpawner sync
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if peer_id in players:
		if multiplayer.is_server():
			var player = players[peer_id]
			if is_instance_valid(player):
				player.queue_free()  # triggers MultiplayerSpawner despawn on clients
		players.erase(peer_id)


func _spawn_player(peer_id: int) -> void:
	if peer_id in players:
		return

	var player: Player = PLAYER_SCENE.instantiate()
	player.name = "Player" + str(peer_id)
	player.position = _get_spawn_position(peer_id)

	# Assign multiplayer authority BEFORE entering scene tree
	# so _ready() sees the correct authority
	player.set_multiplayer_authority(peer_id)

	# Add to scene, second parameter 'true' means force readable name
	# UI setup and dict tracking handled in _on_player_spawned
	$Players.add_child(player, true)


func _on_player_spawned(node: Node) -> void:
	var player := node as Player
	if player == null:
		return

	var peer_id := player.get_multiplayer_authority()
	players[peer_id] = player

	# Only set up UI for the local player on this peer
	if player.is_multiplayer_authority():
		player.inventory_ui = inventory_ui
		player.campfire_ui = campfire_ui
		player.crafting_ui = crafting_ui
		player.setup_local_ui()
		crafting_ui.setup(player.crafter.recipies)

	print("Player tracked for peer %d" % peer_id)


func _get_spawn_position(peer_id: int) -> Vector2:
	return Vector2(
		spawn_point.global_position.x + ((peer_id - 1) * spawn_spacing),
		spawn_point.global_position.y
	)
