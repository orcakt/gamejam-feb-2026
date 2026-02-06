class_name CraftSlot
extends Panel


const LABEL_TEXT: String = "%s - %d"

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label


func fill(item: Item, amount: int) -> void:
	texture_rect.texture = item.texture
	label.text = LABEL_TEXT % [item.name, amount]
