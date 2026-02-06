class_name CraftingUI
extends Control


const SLOT_PATH: String = "res://ui/game/crafting/craft_slot_ui.tscn"

@export var recipies: Array[CraftRecipe]

@export var crafter: Crafter
@export var inventory: Inventory

@onready var input_container: HBoxContainer = %InputContainer
@onready var output_container: OutputContainer = %OutputContainer


func _ready() -> void:
	# load up the possible craftables
	for recipe in recipies:
		output_container.add(recipe.output)
	
	# set the inputs for the current output
	_reset_inputs(recipies[0].inputs)


func _reset_inputs(inputs: Dictionary[Item, int]) -> void:
	# clear the previous inputs
	for child in input_container.get_children():
		child.queue_free()
	
	# set new inputs
	for item: Item in inputs.keys():
		var slot: CraftSlot = _create_slot()
		input_container.add_child(slot)
		slot.fill(item, inputs[item])


#func _on_btn_craft_pressed() -> void:
	#if crafter.can_craft(output.craftable, inventory.items):
		## remove inputs from inventory
		#for input_item in output.craftable.inputs.keys():
			#inventory.remove(input_item, output.craftable.inputs[input_item])
		#
		## add new craftable ( BUT SHOULDNT THIS BE AN ITEM TOOOOO?!?!?! ) to inventory


func _create_slot() -> CraftSlot:
	var scene: PackedScene = load(SLOT_PATH)
	return scene.instantiate()
