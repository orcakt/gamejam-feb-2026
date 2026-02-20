class_name WorldItem
extends Interactable


@export var item: Item

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream: AudioStreamPlayer2D = $AudioStreamPlayer2D


func setup() -> void:
	sprite_2d.texture = item.texture
	#audio_stream.stream = item.stream
