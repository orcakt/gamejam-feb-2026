class_name JournalTab
extends TabBar


var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = voices[0]


func open() -> void:
	visible = true


func select() -> void:
	pass


func next_item() -> void:
	pass


func prev_item() -> void:
	pass


func _speak(text: String) -> void:
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice_id)
