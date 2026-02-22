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

	print("[World._ready] peer=%d is_server=%s" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	$PlayerSpawner.spawned.connect(_on_player_spawned)

	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())
	else:
		# Release the relay peer's packet hold now that world is loaded.
		# This emits peer_connected for pre-existing peers and delivers
		# any data packets that arrived before the scene was ready.
		if NetworkManager.relay_peer:
			NetworkManager.relay_peer.scene_ready()


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

	print("[World._spawn_player] spawning peer_id=%d" % peer_id)
	# Add to scene, second parameter 'true' means force readable name
	$Players.add_child(player, true)

	# spawned signal does NOT fire on the server (only on clients via replication).
	# Do server-side tracking and UI setup here directly.
	players[peer_id] = player
	if player.is_multiplayer_authority():
		player.get_node("Camera2D").enabled = true
		player.inventory_ui = inventory_ui
		player.campfire_ui = campfire_ui
		player.crafting_ui = crafting_ui
		player.setup_local_ui()
		crafting_ui.setup(player.crafter.recipies)
	print("Player tracked for peer %d" % peer_id)


func _on_player_spawned(node: Node) -> void:
	var player := node as Player
	if player == null:
		return

	var local_peer := multiplayer.get_unique_id()
	var auth_before := player.get_multiplayer_authority()
	var peer_id := int(player.name.trim_prefix("Player"))
	player.set_multiplayer_authority(peer_id)
	var auth_after := player.get_multiplayer_authority()
	var is_auth := player.is_multiplayer_authority()

	print("[World._on_player_spawned] local=%d node=%s parsed_id=%d auth_before=%d auth_after=%d is_auth=%s" % [
		local_peer, player.name, peer_id, auth_before, auth_after, is_auth
	])

	players[peer_id] = player

	if is_auth:
		print("[World._on_player_spawned] → setting up local UI for peer %d" % peer_id)
		player.get_node("Camera2D").enabled = true
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
