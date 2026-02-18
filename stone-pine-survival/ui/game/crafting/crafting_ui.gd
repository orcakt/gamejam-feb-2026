class_name CraftingUI
extends Control


const SLOT_PATH: String = "res://ui/game/crafting/craft_slot_ui.tscn"

@export var crafter: Crafter
@export var inventory: Inventory

@onready var input_container: HBoxContainer = %InputContainer
@onready var output_container: OutputContainer = %OutputContainer

var recipies: Dictionary[Item, CraftRecipe]
var current_recipe: CraftRecipe


func open() -> void:
	# load up the possible craftables
	for recipe in recipies.values():
		output_container.add(recipe.output)
	
	# set the inputs for the current output
	current_recipe = recipies.values()[recipies.values().size() - 1]
	_reset_inputs(current_recipe.inputs)
	
	# reveal the ui
	visible = true


func focus_next() -> void:
	var output = output_container.next_item()
	current_recipe = recipies[output]
	_reset_inputs(current_recipe.inputs)


func focus_prev() -> void:
	var output = output_container.prev_item()
	current_recipe = recipies[output]
	_reset_inputs(current_recipe.inputs)


func try_craft() -> void:
	if crafter.can_craft(current_recipe, inventory.items):
		# remove inputs from inventory
		for input_item in current_recipe.inputs.keys():
			inventory.remove(input_item, current_recipe.inputs[input_item])
		
		# add new craftable to inventory
		inventory.add(current_recipe.output, 1)


func _reset_inputs(inputs: Dictionary[Item, int]) -> void:
	# clear the previous inputs
	for child in input_container.get_children():
		child.queue_free()
	
	# set new inputs
	for item: Item in inputs.keys():
		var slot: CraftSlot = _create_slot()
		input_container.add_child(slot)
		slot.fill(item, inputs[item])


func _create_slot() -> CraftSlot:
	var scene: PackedScene = load(SLOT_PATH)
	return scene.instantiate()


func _handle_recipe_added(recipe: CraftRecipe) -> void:
	recipies[recipe.output] = recipe
