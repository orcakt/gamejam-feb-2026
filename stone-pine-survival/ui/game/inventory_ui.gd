class_name InventoryUI
extends Control


const ITEM_SLOT_TEXT: String = "%s - %d"

@export var inventory: Inventory

@onready var item_list: ItemList = %ItemList

var item_dict: Dictionary[Item, int]


func open() -> void:
	visible = true

func close() -> void:
	visible = false


func _ready() -> void:
	inventory.item_updated.connect(_handle_item_updated)


### Sets the value of the item.
func _handle_item_updated(item: Item, value: int) -> void:
	# keep track of item index
	if not item_dict.has(item):
		item_dict[item] = item_list.add_item(
			ITEM_SLOT_TEXT % [item.name, value], 
			item.texture
		)
	elif value == 0:
		item_list.remove_item(item_dict[item])
		item_dict.erase(item)
	else:
		item_list.set_item_text(
			item_dict[item],
			ITEM_SLOT_TEXT % [item.name, value]
		)
