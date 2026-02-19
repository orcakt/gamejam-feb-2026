class_name Land
extends Node2D


@onready var resources: Node2D = $Resources


### Setup is meant to be run after _ready()
func _ready() -> void:
	for resource: WorldItem in resources.get_children():
		resource.setup()
