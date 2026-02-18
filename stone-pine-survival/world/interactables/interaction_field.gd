class_name InteractionField
extends Area2D


signal near_interactable()
signal no_interactables()

var interactables: Array[Interactable]


func can_interact() -> bool:
	return interactables.size() > 0


func interact(pos: Vector2) -> Interactable:
	var closest_interactable: Interactable = interactables[0]
	var closest_distance: float = closest_interactable.global_position.distance_to(pos)
	
	for interactable in interactables:
		if interactable.global_position.distance_to(pos) < closest_distance:
			closest_interactable = interactable
	
	return closest_interactable


func _on_body_entered(body: Interactable) -> void:
	interactables.push_back(body)
	near_interactable.emit()

func _on_body_exited(body: Interactable) -> void:
	interactables.erase(body)
	if interactables.is_empty():
		no_interactables.emit()
