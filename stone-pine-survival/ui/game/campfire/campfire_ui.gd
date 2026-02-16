class_name CampfireUI
extends Control


@onready var amount_lbl: Label = %AmountLbl
@onready var progress_bar: ProgressBar = %ProgressBar

var campfire: Campfire


func connected() -> bool:
	return campfire != null


func interact(cmp: Campfire) -> void:
	campfire = cmp
	visible = true


func disengage() -> void:
	visible = false
	campfire = null


func _process(_delta) -> void:
	if connected():
		var fuel = campfire.current_fuel
		amount_lbl.text = "%s" % floor(fuel)
		progress_bar.value = fuel - floor(fuel)
