extends Node


const WORLD_ITEM_SCENE = preload("uid://c5n4omxism1tl")

@onready var player: Player = $Player
@onready var journal_ui: JournalUI = $CanvasLayer/JournalUI
@onready var campfire_ui: CampfireUI = $CanvasLayer/CampfireUI


func _ready() -> void:
	player.setup_local_ui(journal_ui, campfire_ui)
	player.dropped.connect(_handle_player_dropped_item)


func _handle_player_dropped_item(item: Item, pos: Vector2) -> void:
	var world_item: WorldItem = WORLD_ITEM_SCENE.instantiate()
	add_child(world_item)
	world_item.item = item
	world_item.global_position = pos
	world_item.setup()
