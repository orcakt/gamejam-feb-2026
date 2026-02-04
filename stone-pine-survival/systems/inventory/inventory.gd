class_name Inventory
extends Node


signal item_updated(item: Item, amount: int)

var items: Dictionary[Item, int]


func add(item: Item, amount: int) -> void:
	if items.has(item):
		items[item] += amount
	else:
		items.set(item, amount)
	
	item_updated.emit(item, items[item])


func remove(item: Item, amount: int) -> void:
	if items.has(item):
		items[item] -= amount
		var new_value = items[item]
		
		if new_value <= 0:
			items.erase(item)
			new_value = 0
		
		item_updated.emit(item, new_value)
