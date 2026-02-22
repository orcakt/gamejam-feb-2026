class_name ItemPlacement
extends Sprite2D


@export var distance: int = 15
@export var items: Dictionary[Item, String]

var item: Item


func is_holding() -> bool:
	return item != null


func hold(itm: Item) -> void:
	item = itm
	texture = item.texture


func release() -> Item:
	var path: String = items[item]
	var scene: PackedScene = load(path)
	var held: Interactable = scene.instantiate()
	
	var land: Land = get_tree().get_first_node_in_group("land")
	land.add_child(held)
	held.global_position = global_position
	
	var itm = item
	item = null
	texture = null
	return itm


func cancel() -> void:
	item = null
	texture = null


### Accepts a normalized direction and sets the position accordingly.
func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		position = direction * distance
