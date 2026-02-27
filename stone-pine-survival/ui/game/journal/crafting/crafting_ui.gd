class_name CraftingUI
extends JournalTab


const CRAFT_SLOT_UI = preload("uid://bk7ljxj8gqo47")
const ITEM_SLOT_TEXT: String = "%s - %d"

@export var crafter: Crafter
@export var inventory: Inventory

@onready var selection_section: Node = %Selection
@onready var craft_section: Node = %Craft
@onready var craftable_list: ItemList = %CraftableList
@onready var input_container: HBoxContainer = %InputContainer
@onready var output_slot: CraftSlot = %OutputSlot

var recipies: Dictionary[Item, CraftRecipe]
var current_recipe: CraftRecipe
var is_selecting: bool
var focused_index: int


func setup() -> void:
	for recipe in crafter.recipies:
		recipies[recipe.output] = recipe
		craftable_list.add_item(ITEM_SLOT_TEXT % [recipe.output.name, 1], recipe.output.texture)


func open() -> void:
	# open in the craftable list
	is_selecting = true
	selection_section.visible = true
	
	focused_index = 0
	craftable_list.select(focused_index)
	craft_section.visible = false
	visible = true


func select() -> void:
	if is_selecting:
		var output: Item = recipies.keys()[focused_index]
		output_slot.fill(output, 1)
		
		current_recipe = recipies[output]
		_reset_inputs(current_recipe.inputs)
		
		selection_section.visible = false
		craft_section.visible = true
	if crafter.can_craft(current_recipe, inventory.items):
		# remove inputs from inventory
		for input_item in current_recipe.inputs.keys():
			inventory.remove(input_item, current_recipe.inputs[input_item])
		
		# add new craftable to inventory
		inventory.add(current_recipe.output, 1)


func next_item() -> void:
	if is_selecting:
		# no movement if no items
		if recipies.size() == 0: return
		
		# itterate through the list
		focused_index = (focused_index + 1) % recipies.size()
		craftable_list.select(focused_index)


func prev_item() -> void:
	if is_selecting:
		# no movement if no items
		if recipies.size() == 0: return
		
		# itterate through the list
		focused_index -= 1
		if focused_index < 0:
			focused_index = focused_index + recipies.size()
		craftable_list.select(focused_index)


func step_out() -> bool:
	if is_selecting:
		selection_section.visible = false
		
		return true
	else:
		is_selecting = true
		craft_section.visible = false
		selection_section.visible = true
		
		return false


func _reset_inputs(inputs: Dictionary[Item, int]) -> void:
	# clear the previous inputs
	for child in input_container.get_children():
		child.queue_free()
	
	# set new inputs
	for item: Item in inputs.keys():
		var slot: CraftSlot = CRAFT_SLOT_UI.instantiate()
		input_container.add_child(slot)
		slot.fill(item, inputs[item])


func _handle_recipe_added(recipe: CraftRecipe) -> void:
	recipies[recipe.output] = recipe
