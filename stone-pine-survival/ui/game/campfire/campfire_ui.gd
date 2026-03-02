class_name CampfireUI
extends Control


const INSTRUCTIONS = "Itterate through the inventory and select an item to burn."

@onready var amount_lbl: Label = %AmountLbl
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var burnable_slot_ui: ItemSlotUI = %BurnableSlotUI

var campfire: Campfire
var inventory: Inventory
var burn_counts: Dictionary[Item, int]
var burnables: Array[Item]
var current_focus: int

var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = voices[0]


func connected() -> bool:
	return campfire != null


func open(cmp: Campfire, inv: Inventory) -> void:
	campfire = cmp
	inventory = inv
	
	# fill out ui needed items
	var items = inventory.items
	for item in items.keys():
		if item.burnable:
			burnables.push_back(item)
			burn_counts.set(item, items[item])
	
	# set current burnable
	current_focus = burnables.size() - 1
	var item: Item = burnables[current_focus]
	_update_ui(item)
	
	visible = true
	
	# inform via tts
	_speak("Campfire. Fuel: %s. Instructions: %s" % [
		campfire.current_fuel, INSTRUCTIONS
	])


func close() -> void:
	visible = false
	campfire = null
	inventory = null
	burnable_slot_ui.clear()


func select() -> void:
	# burn item
	var fuel = burnables[current_focus]
	campfire.add_fuel(fuel)
	
	# reduce or remove item from inventory
	inventory.remove(fuel)
	burn_counts[fuel] -= 1
	if not inventory.has(fuel):
		burnables.erase(fuel)
		burn_counts.erase(fuel)
		
		# since the item is gone, shift ahead
		next_item()
	else:
		var item = burnables[current_focus]
		_update_ui(item)
		_speak("Fuel at: %s" % ceili(campfire.current_fuel))


func next_item() -> void:
	# if we have no burnables, show nothing
	if burnables.size() == 0:
		burnable_slot_ui.clear()
		return
	
	# set new focus
	current_focus = (current_focus + 1) % burnables.size()
	
	# set new burnable item
	var item = burnables[current_focus]
	_update_ui(item)
	_speak("Current Item: %s" % item.name)


func prev_item() -> void:
	# if we have no burnables, show nothing
	if burnables.size() == 0:
		burnable_slot_ui.clear()
		return
	
	# set new focus
	current_focus -= 1
	if current_focus < 0:
		current_focus += burnables.size()
	
	# set new burnable item
	var item = burnables[current_focus]
	_update_ui(item)
	_speak("Current Item: %s" % item.name)


func _process(_delta) -> void:
	if connected():
		var fuel = campfire.current_fuel
		amount_lbl.text = "%s" % floor(fuel)
		progress_bar.value = fuel - floor(fuel)


func _update_ui(item: Item) -> void:
	burnable_slot_ui.assign(item, burn_counts[item])


func _speak(text: String) -> void:
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice_id)
