class_name InventoryUI
extends Control


const ITEM_SLOT_TEXT: String = "%s - %d"

@export var inventory: Inventory

@onready var item_list: ItemList = %ItemList

var item_dict: Dictionary[Item, int]
var focused_index: int


func open() -> void:
	visible = true
	focused_index = 0

func close() -> void:
	visible = false

func next_item() -> Item:
	focused_index = (focused_index + 1) % item_dict.size()
	item_list.select(focused_index)
	return item_dict.find_key(focused_index)

func prev_item() -> Item:
	focused_index = (focused_index - 1) % item_dict.size()
	item_list.select(focused_index)
	return item_dict.find_key(focused_index)


### Sets the value of the item.
func _handle_item_updated(item: Item, value: int) -> void:
	# keep track of item index
	if not item_dict.has(item):
		item_dict[item] = item_list.add_item(
			ITEM_SLOT_TEXT % [item.name, value], 
			item.texture
		)
	elif value <= 0:
		var removed_index = item_dict[item]
		item_list.remove_item(removed_index)
		item_dict.erase(item)
		
		# shift higher indicies
		for key in item_dict.keys():
			if removed_index < item_dict[key]:
				item_dict[key] -= 1
	else:
		item_list.set_item_text(
			item_dict[item],
			ITEM_SLOT_TEXT % [item.name, value]
		)
