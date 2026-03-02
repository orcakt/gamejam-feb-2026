class_name InstructionsUI
extends JournalTab


const LABEL_COUNT: int = 5

@export var labels: Dictionary[Label, String]

@onready var instructions: VBoxContainer = %Instructions
@onready var lbl_itter: Label = %LblItteration
@onready var lbl_nav: Label = %LblNavigation
@onready var lbl_select: Label = %LblSelection
@onready var lbl_exit: Label = %LblExit
@onready var lbl_open: Label = %LblOpen

var current_focus: int
var current_label: Label


func open() -> void:
	current_focus = LABEL_COUNT - 1
	visible = true
	
	_speak("Instructions Menu")


func select() -> void:
	_speak(current_label.text)


func next_item() -> void:
	current_focus = (current_focus + 1) % LABEL_COUNT
	_focus_and_identify(current_focus)


func prev_item() -> void:
	current_focus -= 1
	if current_focus < 0:
		current_focus += LABEL_COUNT
	_focus_and_identify(current_focus)


func _focus_and_identify(index: int) -> void:
	current_label = instructions.get_child(index)
	current_label.grab_focus()
	
	var summary: String = labels[current_label]
	_speak(summary)
