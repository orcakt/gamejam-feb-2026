class_name Crafter
extends Node

func can_craft(craftable: Craftable, items: Dictionary[Item, int]) -> bool:
	for key in craftable.inputs.keys():
		if not items.has(key):
			return false
		elif items.get(key) < craftable.inputs.get(key):
			return false
	
	# if all items are found and have the required amount
	return true
