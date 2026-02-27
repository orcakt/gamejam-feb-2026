extends Node


@export var items: Dictionary[Item, int]

@onready var inventory: Inventory = $Inventory
@onready var journal: JournalUI = %JournalUI


func _ready() -> void:
	journal.setup()
	
	for item in items.keys():
		inventory.add(item, items[item])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_journal_menu"):
		journal.open(JournalUI.Page.INSTR)
	elif event.is_action_pressed("open_inventory_menu"):
		journal.open(JournalUI.Page.INVEN)
	elif event.is_action_pressed("open_crafting_menu"):
		journal.open(JournalUI.Page.CRAFT)
	elif event.is_action_pressed("ui_accept"):
		journal.select()	
	elif event.is_action_pressed("ui_focus_next"):
		journal.next_tab()
	elif event.is_action_pressed("ui_focus_prev"):
		journal.prev_tab()
	elif event.is_action_pressed("ui_right"):
		journal.next_item()
	elif event.is_action_pressed("ui_left"):
		journal.prev_item()
	elif event.is_action_pressed("ui_cancel"):
		journal.close()
