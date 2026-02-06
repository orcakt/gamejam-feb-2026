class_name OutputContainer
extends HBoxContainer


const SLOT_PATH: String = "res://ui/game/crafting/craft_slot_ui.tscn"

var outputs: Array[Item]
var focused_index: int


func add(item: Item) -> void:
	outputs.push_back(item)


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
	remove_child(get_child(0))
	var scene: PackedScene = load(SLOT_PATH)
	var slot: CraftSlot = scene.instantiate()
	slot.fill(item, 1)
	add_child(slot)
