class_name WorldItem
extends Interactable


var item: Item

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D


func setup(data: Item) -> void:
	sprite_2d.texture = data.texture
	audio_stream.stream = data.stream


func _ready() -> void:
	interaction = _callback


func _callback() -> void:
	pass
