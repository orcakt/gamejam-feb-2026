extends Node

var _assertive_label: Label
var _polite_label: Label

func _ready() -> void:
	_assertive_label = Label.new()
	_assertive_label.accessibility_live = DisplayServer.LIVE_ASSERTIVE
	_assertive_label.focus_mode = Control.FOCUS_NONE
	_assertive_label.position = Vector2(-10000, -10000)
	add_child(_assertive_label)

	_polite_label = Label.new()
	_polite_label.accessibility_live = DisplayServer.LIVE_POLITE
	_polite_label.focus_mode = Control.FOCUS_NONE
	_polite_label.position = Vector2(-10000, -10000)
	add_child(_polite_label)

## Announces text to the screen reader immediately, interrupting current speech.
## Use for urgent messages: health warnings, hazards, important events.
func speak(text: String) -> void:
	_announce(_assertive_label, text)

## Announces text to the screen reader politely, after current speech finishes.
## Use for non-urgent info: item pickups, crafting results, ambient descriptions.
func speak_polite(text: String) -> void:
	_announce(_polite_label, text)

func _announce(label: Label, text: String) -> void:
	# If the text is identical to the current label text, the screen reader
	# won't fire because no change occurred. Clear first to force a re-announce.
	if label.text == text:
		label.text = ""
	label.text = text
