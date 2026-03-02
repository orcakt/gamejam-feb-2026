class_name ItemSlotUI
extends Panel


const LABEL_TEXT: String = "%s - %d"

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label


func assign(item: Item, amount: int) -> void:
	texture_rect.texture = item.texture
	label.text = LABEL_TEXT % [item.name, amount]


func clear() -> void:
	texture_rect.texture = null
	label.text = ""
