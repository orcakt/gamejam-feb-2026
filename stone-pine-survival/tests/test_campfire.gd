extends Node


const LABEL_TEMPLATE: String = "FUEL: %3.2f"
@export var fuel_types: Dictionary[String, Item]

@onready var campfire: Campfire = $Campfire
@onready var fuel_lbl: Label = %FuelLbl


func _on_increment_btn_pressed() -> void:
	campfire._increment()

func _on_decrement_btn_pressed() -> void:
	campfire._decrement()

func _on_bark_btn_pressed() -> void:
	campfire.add_fuel(fuel_types["bark"])

func _on_stick_btn_pressed() -> void:
	campfire.add_fuel(fuel_types["stick"])


func _process(_delta) -> void:
	fuel_lbl.text = LABEL_TEMPLATE % campfire.current_fuel
