class_name InteractPopup
extends PopupUI


@onready var animation: AnimationPlayer = $AnimationPlayer


func open() -> void:
	animation.play("open")


func close() -> void:
	animation.play_backwards("open")
