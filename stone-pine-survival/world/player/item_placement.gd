class_name ItemPlacement
extends Marker2D


@export var distance: int = 15
@export var items: Dictionary[Item, String]

var held: Interactable
var item: Item


func is_holding() -> bool:
	return held != null


func hold(itm: Item) -> void:
	item = itm
	var path: String = items[item]
	var scene: PackedScene = load(path)
	held = scene.instantiate()
	add_child(held)


func release() -> Item:
	var land: Land = get_tree().get_first_node_in_group("land")
	held.reparent(land)
	held = null
	return item


func cancel() -> void:
	remove_child(held)
	held = null
	item = null


### Accepts a normalized direction and sets the position accordingly.
func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		position = direction * distance
