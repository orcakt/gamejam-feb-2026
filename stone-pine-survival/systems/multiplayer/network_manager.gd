# Initial network manager implementation
# Connects to the server I have going by default. 
extends Node

signal relay_peer_connected
signal relay_peer_connection_failed

var relay_peer: RelayMultiplayerPeer
var _relay_url: String = "wss://survival.iamtalon.me/ws"
var _connection_in_progress: bool = false


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta):
	# always poll the relay peer every frame
	if relay_peer:
		relay_peer._do_poll()


func set_relay_url(url: String) -> void:
	_relay_url = url


func get_relay_url() -> String:
	return _relay_url


# The server host is always peerID 1
func host_game(room_code: String) -> void:
	_connect_to_relay(room_code)


func join_game(room_code: String) -> void:
	_connect_to_relay(room_code)


func leave_game() -> void:
	_connection_in_progress = false
	if relay_peer:
		relay_peer.disconnect_from_relay()
		relay_peer = null
	multiplayer.multiplayer_peer = null


func _connect_to_relay(room_code: String) -> void:
	if _connection_in_progress:
		return

	_connection_in_progress = true

	if relay_peer:
		if relay_peer.connected_to_relay.is_connected(_on_relay_connected):
			relay_peer.connected_to_relay.disconnect(_on_relay_connected)
		if relay_peer.connection_failed.is_connected(_on_relay_failed):
			relay_peer.connection_failed.disconnect(_on_relay_failed)
		if relay_peer.peer_joined.is_connected(_on_relay_peer_joined):
			relay_peer.peer_joined.disconnect(_on_relay_peer_joined)
		if relay_peer.peer_left.is_connected(_on_relay_peer_left):
			relay_peer.peer_left.disconnect(_on_relay_peer_left)
		relay_peer.disconnect_from_relay()

	relay_peer = RelayMultiplayerPeer.new()

	relay_peer.connected_to_relay.connect(_on_relay_connected)
	relay_peer.connection_failed.connect(_on_relay_failed)
	relay_peer.peer_joined.connect(_on_relay_peer_joined)
	relay_peer.peer_left.connect(_on_relay_peer_left)

	var err = relay_peer.connect_to_relay(_relay_url, room_code)
	if err != OK:
		push_error("Failed to connect to relay: %s" % error_string(err))
		_connection_in_progress = false
		relay_peer_connection_failed.emit()
		return

	# this is the godot high level multiplayer magic
	multiplayer.multiplayer_peer = relay_peer


func _on_relay_connected() -> void:
	_connection_in_progress = false
	print("Connected to relay!")
	print("My peer ID: %d" % multiplayer.get_unique_id())
	print("Am I the host? %s" % multiplayer.is_server())

	relay_peer_connected.emit()


func _on_relay_failed() -> void:
	_connection_in_progress = false
	push_error("Failed to connect to relay server!")
	relay_peer_connection_failed.emit()


func _on_relay_peer_joined(peer_id: int) -> void:
	print("Relay: peer %d joined" % peer_id)


func _on_relay_peer_left(peer_id: int) -> void:
	print("Relay: peer %d left" % peer_id)


# Standard Godot multiplayer signals
func _on_peer_connected(peer_id: int) -> void:
	print("Multiplayer: peer %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Multiplayer: peer %d disconnected" % peer_id)


func _on_connected_to_server() -> void:
	print("Connected to server (host)")


func _on_server_disconnected() -> void:
	print("Server (host) disconnected!")
