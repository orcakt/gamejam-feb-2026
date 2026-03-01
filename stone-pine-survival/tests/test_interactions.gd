extends Node


@onready var player: Player = $Player
@onready var journal_ui: JournalUI = $CanvasLayer/JournalUI
@onready var campfire_ui: CampfireUI = $CanvasLayer/CampfireUI


func _ready() -> void:
	player.journal_ui = journal_ui
	player.campfire_ui = campfire_ui
	player.setup_local_ui()
	journal_ui.crafting_ui.setup()
