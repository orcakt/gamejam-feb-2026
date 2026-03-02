class_name InteractPopup
extends PopupUI


enum Message {
	INTERACT,
	PLACE
}

@export var interact_msg: String = "Interact ( Space )"
@export var place_msg: String = "Place ( Space ) / Cancel ( Esc )"

@onready var label: Label = %Label
@onready var animation: AnimationPlayer = $AnimationPlayer


@rpc("call_local")
func set_msg(msg: Message) -> void:
	match msg:
		Message.INTERACT:
			label.text = interact_msg
		Message.PLACE:
			label.text = place_msg


@rpc("call_local")
func open() -> void:
	animation.play("open")


@rpc("call_local")
func close() -> void:
	animation.play_backwards("open")
