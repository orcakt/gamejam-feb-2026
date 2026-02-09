class_name Crafter
extends Node


signal recipe_added(recipe: CraftRecipe)

var recipies: Array[CraftRecipe]


func add(recipe: CraftRecipe) -> void:
	recipies.push_back(recipe)
	recipe_added.emit(recipe)


func get_recipe(item: Item) -> CraftRecipe:
	for recipe in recipies:
		if recipe.output == item:
			return recipe
	return null


func can_craft(recipe: CraftRecipe, items: Dictionary[Item, int]) -> bool:
	for key in recipe.inputs.keys():
		if not items.has(key):
			return false
		elif items.get(key) < recipe.inputs.get(key):
			return false
	
	# if all items are found and have the required amount
	return true
