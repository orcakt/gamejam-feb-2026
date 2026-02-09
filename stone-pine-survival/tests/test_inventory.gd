extends Node


const BARK = preload("uid://dbs51qiyrnao2")
const BERRY = preload("uid://cbo8yid1nwxh1")
const STICK = preload("uid://b67dkh1b4y8w2")
const STONE = preload("uid://m0lwpdmuf2p8")
const VINE = preload("uid://bkm6qnmvgoimu")

@onready var inventory: Inventory = $Inventory


func _on_btn_rem_stick_pressed() -> void:
	inventory.remove(STICK, 1)

func _on_btn_add_stick_pressed() -> void:
	inventory.add(STICK, 1)


func _on_btn_rem_stone_pressed() -> void:
	inventory.remove(STONE, 1)

func _on_btn_add_stone_pressed() -> void:
	inventory.add(STONE, 1)


func _on_btn_rem_bark_pressed() -> void:
	inventory.remove(BARK, 1)

func _on_btn_add_bark_pressed() -> void:
	inventory.add(BARK, 1)


func _on_btn_rem_vine_pressed() -> void:
	inventory.remove(VINE, 1)

func _on_btn_add_vine_pressed() -> void:
	inventory.add(VINE, 1)


func _on_btn_rem_berry_pressed() -> void:
	inventory.remove(BERRY, 1)

func _on_btn_add_berry_pressed() -> void:
	inventory.add(BERRY, 1)
