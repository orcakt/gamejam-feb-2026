extends Control

@onready var room_code_input: LineEdit = %RoomCodeInput
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton

var _is_connecting: bool = false


func _ready() -> void:
	room_code_input.grab_focus()
	_update_button_states()

	room_code_input.text_changed.connect(_on_room_code_changed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

	NetworkManager.relay_peer_connected.connect(_on_connection_success)
	NetworkManager.relay_peer_connection_failed.connect(_on_connection_failed)


func _on_room_code_changed(_new_text: String) -> void:
	_update_button_states()


func _update_button_states() -> void:
	var has_text: bool = room_code_input.text.strip_edges().length() > 0
	var can_interact: bool = has_text and not _is_connecting

	host_button.disabled = not can_interact
	join_button.disabled = not can_interact

	if _is_connecting:
		host_button.text = "Connecting..."
		join_button.text = "Connecting..."
	else:
		host_button.text = "Host game"
		join_button.text = "Join game"


func _on_host_pressed() -> void:
	_attempt_connection("host")


func _on_join_pressed() -> void:
	_attempt_connection("join")


func _attempt_connection(mode: String) -> void:
	if _is_connecting:
		return

	var room_code: String = room_code_input.text.strip_edges()
	if room_code.is_empty():
		return

	_is_connecting = true
	_update_button_states()

	if mode == "host":
		NetworkManager.host_game(room_code)
	else:
		NetworkManager.join_game(room_code)


func _on_connection_success() -> void:
	_is_connecting = false
	print("Main Menu: Connection successful, transitioning to game world")

	# Transition to game world
	get_tree().change_scene_to_file("res://world/world.tscn")


func _on_connection_failed() -> void:
	_is_connecting = false
	_update_button_states()

	push_error("Connection Error: Failed to connect. Please check your room code and try again.")
