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
	inventory.item_updated.connect(inventory_ui._handle_item_updated)
	
	crafting_ui.setup()
	current_tab = instructions_ui


func open(page: Page = Page.INSTR) -> void:
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
	if current_page == Page.CRAFT:
		var leave_journal = crafting_ui.step_out()
		visible = !leave_journal
	else:
		visible = false


func select() -> void:
	# ensure the journal is open
	if not visible: return
	
	current_tab.select()


func next_tab() -> void:
	# ensure the journal is open
	if not visible: return
	
	match current_page:
		Page.INSTR:
			current_tab = inventory_ui
			current_page = Page.INVEN
		Page.INVEN:
			current_tab = crafting_ui
			current_page = Page.CRAFT
		Page.CRAFT:
			current_tab = instructions_ui
			current_page = Page.INSTR
	
	current_tab.open()


func prev_tab() -> void:
	# ensure the journal is open
	if not visible: return
	
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


func next_item() -> void:
	# ensure the journal is open
	if not visible: return
	
	current_tab.next_item()


func prev_item() -> void:
	# ensure the journal is open
	if not visible: return
	
	current_tab.prev_item()
