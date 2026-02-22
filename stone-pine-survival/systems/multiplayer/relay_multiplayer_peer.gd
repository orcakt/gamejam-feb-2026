# A custom MultiplayerPeer that connects to our relay server.
# Allows use of @rpc, MultiplayerSynchronizer, MultiplayerSpawner, etc.
extends MultiplayerPeerExtension
class_name RelayMultiplayerPeer

signal connected_to_relay
signal connection_failed
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

# Message types
const MSG_JOIN_ROOM = 1
const MSG_ROOM_JOINED = 2
const MSG_PEER_JOINED = 3
const MSG_PEER_LEFT = 4
const MSG_DATA = 10

# Transfer modes mapping. These are websockets so they're all gonna be the same. If websockets turn out to be a problem we can still switch to webrtc, but this is much easier and will work without issues in web builds. We just have to be careful with how we send data, but it is definitely doable. 
const TRANSFER_MODE_MAP = {
	MultiplayerPeer.TRANSFER_MODE_UNRELIABLE: WebSocketPeer.WRITE_MODE_BINARY,
	MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED: WebSocketPeer.WRITE_MODE_BINARY,
	MultiplayerPeer.TRANSFER_MODE_RELIABLE: WebSocketPeer.WRITE_MODE_BINARY,
}

var _socket: WebSocketPeer = WebSocketPeer.new()
var _my_peer_id: int = 0
var _peers: Array[int] = []
var _join_room_sent: bool = false
var _connection_status: MultiplayerPeer.ConnectionStatus = MultiplayerPeer.CONNECTION_DISCONNECTED
var _target_peer: int = 0
var _transfer_mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
var _transfer_channel: int = 0

# Incoming packet queue
var _incoming_packets: Array[Dictionary] = []
var _current_packet_peer: int = 0

var _waiting_for_scene_ready: bool = false
var _held_packets: Array[Dictionary] = []
var _flush_deferred: bool = false

var _room_code: String = ""
var _relay_url: String = ""


func connect_to_relay(url: String, room_code: String) -> Error:
	_relay_url = url
	_room_code = room_code
	_join_room_sent = false
	_connection_status = MultiplayerPeer.CONNECTION_CONNECTING
	
	var err = _socket.connect_to_url(url)
	if err != OK:
		_connection_status = MultiplayerPeer.CONNECTION_DISCONNECTED
		connection_failed.emit()
		return err
	
	return OK


func disconnect_from_relay():
	_join_room_sent = false
	_socket.close()
	_connection_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_my_peer_id = 0
	_peers.clear()
	_incoming_packets.clear()
	_held_packets.clear()
	_waiting_for_scene_ready = false
	_flush_deferred = false


func scene_ready() -> void:
	# Only set the flag, emission and packet delivery happen inside _do_poll()
	# so that peer_connected and packet availability are atomic within one poll cycle.
	_flush_deferred = true


func _do_poll() -> void:
	# Atomically emit peer_connected for pre-existing peers and deliver held
	# packets. Both happen before _socket.poll() so that
	# connected_peers is populated before any new packets arrive, and
	# everything occurs within one _do_poll() call, SceneMultiplayer
	#       only reads _incoming_packets after _do_poll() returns.
	if _flush_deferred:
		_flush_deferred = false
		_waiting_for_scene_ready = false
		for peer_id in _peers:
			peer_connected.emit(peer_id)
		_incoming_packets.append_array(_held_packets)
		_held_packets.clear()

	_socket.poll()

	var state = _socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if _connection_status == MultiplayerPeer.CONNECTION_CONNECTING and not _join_room_sent:
				# Just connected, join the room
				_send_join_room()
				_join_room_sent = true

			# Process incoming messages
			while _socket.get_available_packet_count() > 0:
				var packet = _socket.get_packet()
				_handle_relay_message(packet)

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			if _connection_status != MultiplayerPeer.CONNECTION_DISCONNECTED:
				_connection_status = MultiplayerPeer.CONNECTION_DISCONNECTED
				var code = _socket.get_close_code()
				var reason = _socket.get_close_reason()
				print("WebSocket closed: %d %s" % [code, reason])


func _send_join_room():
	var packet = PackedByteArray()
	packet.append(MSG_JOIN_ROOM)
	packet.append_array(_room_code.to_utf8_buffer())
	_socket.send(packet)


func _handle_relay_message(data: PackedByteArray):
	if data.size() < 1:
		return
	
	var msg_type = data[0]
	
	match msg_type:
		MSG_ROOM_JOINED:
			_handle_room_joined(data)
		MSG_PEER_JOINED:
			_handle_peer_joined(data)
		MSG_PEER_LEFT:
			_handle_peer_left(data)
		MSG_DATA:
			_handle_data(data)


func _handle_room_joined(data: PackedByteArray):
	if data.size() < 9:
		return
	
	_my_peer_id = data.decode_u32(1)
	var num_peers = data.decode_u32(5)
	
	_peers.clear()
	for i in range(num_peers):
		var peer_id = data.decode_u32(9 + i * 4)
		_peers.append(peer_id)
	
	_connection_status = MultiplayerPeer.CONNECTION_CONNECTED
	connected_to_relay.emit()
	print("Connected to relay as peer %d, existing peers: %s" % [_my_peer_id, _peers])
	# Clients must wait for the game scene to load before emitting peer_connected
	# or delivering data packets otherwise spawn data arrives before the spawner exists.
	if _my_peer_id != 1:
		_waiting_for_scene_ready = true


func _handle_peer_joined(data: PackedByteArray):
	if data.size() < 5:
		return

	var peer_id = data.decode_u32(1)
	if peer_id not in _peers:
		_peers.append(peer_id)
		if not _waiting_for_scene_ready:
			peer_connected.emit(peer_id)   # safe: scene is already loaded
		peer_joined.emit(peer_id)
		print("Peer %d joined" % peer_id)


func _handle_peer_left(data: PackedByteArray):
	if data.size() < 5:
		return

	var peer_id = data.decode_u32(1)
	_peers.erase(peer_id)
	peer_disconnected.emit(peer_id)
	peer_left.emit(peer_id)
	print("Peer %d left" % peer_id)


func _handle_data(data: PackedByteArray):
	if data.size() < 5:
		return
	
	var sender_id = data.decode_u32(1)
	var game_data = data.slice(5)
	# print("[RelayPeer] data from sender=%d (holding=%s)" % [sender_id, _waiting_for_scene_ready])
	var packet = {"peer": sender_id, "data": game_data}
	if _waiting_for_scene_ready:
		_held_packets.append(packet)
	else:
		_incoming_packets.append(packet)



# MultiplayerPeerExtension overrides


func _get_packet_script() -> PackedByteArray:
	# This is called by the engine to get the next packet
	if _incoming_packets.is_empty():
		return PackedByteArray()

	var packet = _incoming_packets[0]
	_current_packet_peer = packet["peer"]

	var result = packet["data"]
	_incoming_packets.remove_at(0)
	return result


func _put_packet_script(p_buffer: PackedByteArray) -> Error:
	if _connection_status != MultiplayerPeer.CONNECTION_CONNECTED:
		return ERR_UNCONFIGURED
	
	# Build relay message: [MSG_DATA][target:4][data...]
	var packet = PackedByteArray()
	packet.append(MSG_DATA)
	
	# Encode target peer (0 = broadcast)
	var target_bytes = PackedByteArray()
	target_bytes.resize(4)
	target_bytes.encode_u32(0, _target_peer if _target_peer > 0 else 0)
	packet.append_array(target_bytes)
	
	packet.append_array(p_buffer)
	
	_socket.send(packet)
	return OK


func _get_available_packet_count() -> int:
	return _incoming_packets.size()


func _get_max_packet_size() -> int:
	return 1 << 24  # 16 MB


func _get_packet_channel() -> int:
	return 0


func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return MultiplayerPeer.TRANSFER_MODE_RELIABLE


func _get_packet_peer() -> int:
	if not _incoming_packets.is_empty():
		return _incoming_packets[0]["peer"]
	return _current_packet_peer  # fallback when queue is empty


func _is_server() -> bool:
	# Peer ID 1 is the host by convention
	return _my_peer_id == 1


func _is_server_relay_supported() -> bool:
	return true


func _get_unique_id() -> int:
	return _my_peer_id


func _set_target_peer(p_peer: int) -> void:
	_target_peer = p_peer


func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return _connection_status


func _set_transfer_channel(p_channel: int) -> void:
	_transfer_channel = p_channel


func _get_transfer_channel() -> int:
	return _transfer_channel


func _set_transfer_mode(p_mode: MultiplayerPeer.TransferMode) -> void:
	_transfer_mode = p_mode


func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _transfer_mode


func _poll() -> void:
	_do_poll()


func _close() -> void:
	disconnect_from_relay()


func _disconnect_peer(p_peer: int, p_force: bool) -> void:
	# Relay doesn't support kicking peers directly yet
	# We can add this if we need it but it's probably enough to do it in the game itself?
	pass
