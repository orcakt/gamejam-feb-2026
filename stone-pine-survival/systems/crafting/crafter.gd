class_name Crafter
extends Node


@export var recipies: Dictionary[Item, CraftRecipe]


func get_recipe(item: Item) -> CraftRecipe:
	if recipies.has(item):
		return recipies[item]
	else:
		return null


func can_craft(recipe: CraftRecipe, items: Dictionary[Item, int]) -> bool:
	for key in recipe.inputs.keys():
		if not items.has(key):
			return false
		elif items.get(key) < recipe.inputs.get(key):
			return false
	
	# if all items are found and have the required amount
	return true
