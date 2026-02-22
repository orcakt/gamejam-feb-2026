class_name EnvironmentZone
extends Area2D

enum EnvironmentType { MEADOW, FOREST, BEACH, RIVER }

signal player_entered(zone: EnvironmentZone)
signal player_exited(zone: EnvironmentZone)

@export_group("Identity")
@export var environment_type: EnvironmentType = EnvironmentType.MEADOW
@export var display_name: String = ""

@export_group("Priority")
## Higher priority wins when zones overlap. Use 0 for backgrounds.
@export var zone_priority: int = 0


# Connected in .tscn
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited.emit(self)


## Returns display_name if set, otherwise the enum key string.
func get_label() -> String:
	return display_name if display_name != "" else EnvironmentType.keys()[environment_type]
