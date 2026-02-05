class_name CraftingUI
extends Control


@export var crafter: Crafter
@export var inventory: Inventory

@onready var left_input: TextureRect = %LeftInput
@onready var right_input: TextureRect = %RightInput
@onready var output: TextureRect = %Output


func _on_btn_craft_pressed() -> void:
	if crafter.can_craft(output.craftable, inventory.items):
		# remove inputs from inventory
		for input_item in output.craftable.inputs.keys():
			inventory.remove(input_item, output.craftable.inputs[input_item])
		
		# add new craftable ( BUT SHOULDNT THIS BE AN ITEM TOOOOO?!?!?! ) to inventory
		
