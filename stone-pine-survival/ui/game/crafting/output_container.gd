class_name OutputContainer
extends HBoxContainer


const SLOT_PATH: String = "res://ui/game/crafting/craft_slot_ui.tscn"

var outputs: Array[Item]
var focused_index: int


func add(item: Item) -> void:
	outputs.push_back(item)
	_reset_output(item)
	
	focused_index = outputs.size() - 1

func next_item() -> Item:
	focused_index = (focused_index + 1) % outputs.size()
	var output: Item = outputs[focused_index]
	_reset_output(output)
	return output

func prev_item() -> Item:
	focused_index = (focused_index - 1) % outputs.size()
	var output: Item = outputs[focused_index]
	_reset_output(output)
	return output


func _reset_output(item: Item) -> void:
	# clear existing
	if get_child_count() > 0:
		remove_child(get_child(0))
	
	# add current
	var scene: PackedScene = load(SLOT_PATH)
	var slot: CraftSlot = scene.instantiate()
	add_child(slot)
	slot.fill(item, 1)
