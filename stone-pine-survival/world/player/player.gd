class_name Player
extends CharacterBody2D


const SPEED = 100.0

@onready var interaction_field: InteractionField = $InteractionField
@onready var inventory: Inventory = $Inventory
@onready var interact_popup: InteractPopup = %InteractPopup


func _ready() -> void:
	# Only enable camera for the local player
	$Camera2D.enabled = is_multiplayer_authority()


func _physics_process(delta):
	# Remote players will have their position synced via MultiplayerSynchronizer
	if is_multiplayer_authority():
		player_movement(delta)


func _input(event) -> void:
	if event.is_action_pressed("interact") && interaction_field.can_interact():
		var interactable: Interactable = interaction_field.interact(global_position)
		if interactable is WorldItem:
			# add item to inventory
			inventory.add(interactable.item, 1)
			interactable.destroy()


func player_movement(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * SPEED
	if Input.is_action_pressed("ui_left"):
		play_anim("left")
	elif Input.is_action_pressed("ui_right"):
		play_anim("right")
	elif Input.is_action_pressed("ui_down"):
		play_anim("down")
	elif Input.is_action_pressed("ui_up"):
		play_anim("up")
	else:
		play_anim("idle")
	
	move_and_slide()


func play_anim(direction):
	var anim = $AnimatedSprite2D
	
	match direction:
		"right":
			anim.flip_h = false
			anim.play("walk_side")
		"left":
			anim.flip_h = true
			anim.play("walk_side")
		"down":
			anim.play("walk_down")
		"up":
			anim.play("walk_up")
		"idle":
			anim.play("idle")


func _on_interaction_field_near_interactable() -> void:
	interact_popup.open()


func _on_interaction_field_no_interactables() -> void:
	interact_popup.close()
