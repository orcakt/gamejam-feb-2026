class_name Land
extends Node2D


@onready var resources: Node2D = $Resources


func _ready() -> void:
	for resource: WorldItem in resources.get_children():
		resource.setup()
