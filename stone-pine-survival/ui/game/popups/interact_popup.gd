class_name InteractPopup
extends PopupUI


enum Message {
	INTERACT,
	PLACE
}

@export var interact_msg: String = "Interact ( E )"
@export var place_msg: String = "Place ( E ) / Cancel ( Esc )"

@onready var label: Label = %Label
@onready var animation: AnimationPlayer = $AnimationPlayer


func set_msg(msg: Message) -> void:
	match msg:
		Message.INTERACT:
			label.text = interact_msg
		Message.PLACE:
			label.text = place_msg


func open() -> void:
	animation.play("open")


func close() -> void:
	animation.play_backwards("open")
