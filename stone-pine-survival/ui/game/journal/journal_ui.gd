class_name JournalUI
extends Control


enum Page {
	INSTR,
	INVEN,
	CRAFT
}

@export var inventory: Inventory
@export var crafter: Crafter

@onready var instructions_ui: InstructionsUI = %InstructionsUI
@onready var inventory_ui: InventoryUI = %InventoryUI
@onready var crafting_ui: CraftingUI = %CraftingUI

var current_page: Page
var current_tab: JournalTab


func setup() -> void:
	crafting_ui.crafter = crafter
	crafting_ui.inventory = inventory
	
	crafting_ui.setup()
	instructions_ui.select()


func open(page: Page) -> void:
	current_page = page
	
	match current_page:
		Page.INSTR:
			current_tab = instructions_ui
		Page.INVEN:
			current_tab = inventory_ui
		Page.CRAFT:
			current_tab = crafting_ui
	
	current_tab.open()
	visible = true


func close() -> void:
	visible = false


func next_tab() -> void:
	match current_page:
		Page.INSTR:
			current_tab = crafting_ui
			current_page = Page.CRAFT
		Page.INVEN:
			current_tab = instructions_ui
			current_page = Page.INSTR
		Page.CRAFT:
			current_tab = inventory_ui
			current_page = Page.INVEN
	
	current_tab.open()


func prev_tab() -> void:
	match current_page:
		Page.INSTR:
			current_tab = crafting_ui
			current_page = Page.CRAFT
		Page.INVEN:
			current_tab = instructions_ui
			current_page = Page.INSTR
		Page.CRAFT:
			current_tab = inventory_ui
			current_page = Page.INVEN
	
	current_tab.open()


func select() -> void:
	current_tab.select()


func next_item() -> void:
	current_tab.next_item()


func prev_item() -> void:
	current_tab.prev_item()
