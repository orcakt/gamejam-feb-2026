class_name Land
extends Node2D


const WORLD_ITEM_SCENE = preload("uid://c5n4omxism1tl")

@onready var resources: Node2D = $Resources


@rpc("any_peer", "call_local")
func place_item(item: Item, pos: Vector2) -> void:
	var world_item: WorldItem = WORLD_ITEM_SCENE.instantiate()
	resources.add_child(world_item)
	world_item.item = item
	world_item.global_position = pos
	world_item.setup()


func _ready() -> void:
	for resource: WorldItem in resources.get_children():
		resource.setup()
