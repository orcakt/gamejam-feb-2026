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
	
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = "Player" + str(peer_id)
	
	# we'll change this once we have logic for this
	player.position = _get_spawn_position(peer_id)
	
	# connect UI
	player.inventory_ui = inventory_ui
	player.campfire_ui = campfire_ui
	player.crafting_ui = crafting_ui
	
	# Add to scene, second parameter 'true' means force readable name
	$Players.add_child(player, true)
	player.crafting_ui.setup(player.crafter.recipies)
	
	# Assign multiplayer authority to the owning peer
	player.set_multiplayer_authority(peer_id)
	
	players[peer_id] = player
	
	print("Spawned player for peer %d at position %s (Authority: %d)" % [peer_id, player.position, player.get_multiplayer_authority()])


func _get_spawn_position(peer_id: int) -> Vector2:
	return Vector2(
		spawn_point.global_position.x + ((peer_id - 1) * spawn_spacing),
		spawn_point.global_position.y
	)
