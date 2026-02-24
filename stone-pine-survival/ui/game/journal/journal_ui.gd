class_name JournalUI
extends Control


enum Page {
	INSTR,
	INVEN,
	CRAFT
}

@onready var instructions: InstructionsUI = %InstructionsUI
@onready var inventory: InventoryUI = %InventoryUI
@onready var crafting: CraftingUI = %CraftingUI

var current_page: Page
var current_tab: JournalTab


func open(page: Page) -> void:
	current_page = page
	
	match current_page:
		Page.INSTR:
			current_tab = instructions
		Page.INVEN:
			current_tab = inventory
		Page.CRAFT:
			current_tab = crafting
	
	current_tab.open()
	visible = true


func close() -> void:
	visible = false


func next_tab() -> void:
	match current_page:
		Page.INSTR:
			current_tab = crafting
			current_page = Page.CRAFT
		Page.INVEN:
			current_tab = instructions
			current_page = Page.INSTR
		Page.CRAFT:
			current_tab = inventory
			current_page = Page.INVEN
	
	current_tab.open()


func prev_tab() -> void:
	match current_page:
		Page.INSTR:
			current_tab = crafting
			current_page = Page.CRAFT
		Page.INVEN:
			current_tab = instructions
			current_page = Page.INSTR
		Page.CRAFT:
			current_tab = inventory
			current_page = Page.INVEN
	
	current_tab.open()


func select() -> void:
	current_tab.select()


func next_item() -> void:
	current_tab.next_item()


func prev_item() -> void:
	current_tab.prev_item()
