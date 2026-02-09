extends Node


@export var items: Dictionary[Item, int]
@export var recipes: Array[CraftRecipe]

@onready var crafting_ui: CraftingUI = $CanvasLayer/CraftingUI
@onready var inventory_ui: InventoryUI = $CanvasLayer/InventoryUI
@onready var inventory: Inventory = $Inventory
@onready var crafter: Crafter = $Crafter


func _ready() -> void:
	for item in items:
		inventory.add(item, items[item])
	
	for recipe in recipes:
		crafter.add(recipe)


func _input(event) -> void:
	if event.is_action_pressed("open_crafting_menu"):
		crafting_ui.open()
		inventory_ui.open()
	elif event.is_action_pressed("ui_right"):
			crafting_ui.focus_next()
	elif event.is_action_pressed("ui_left"):
		crafting_ui.focus_prev()
	elif event.is_action_pressed("craft_item"):
		crafting_ui.try_craft()
