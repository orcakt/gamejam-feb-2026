class_name InteractionField
extends Area2D


signal near_interactable()

var interactables: Array[Interactable]


func interact(pos: Vector2) -> Callable:
	var closest_interactable: Interactable = interactables[0]
	var closest_distance: float = closest_interactable.global_position.distance_to(pos)
	
	for interactable in interactables:
		if interactable.global_position.distance_to(pos) < closest_distance:
			closest_interactable = interactable
	
	return closest_interactable.interaction


func _on_body_entered(body: Interactable) -> void:
	interactables.push_back(body)
	near_interactable.emit()

func _on_body_exited(body: Interactable) -> void:
	interactables.erase(body)
