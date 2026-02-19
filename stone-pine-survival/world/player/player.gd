class_name Player
extends CharacterBody2D


enum InputState {
	WORLD,
	UI
}

const SPEED = 100.0

@export var campfire_ui: CampfireUI
@export var inventory_ui: InventoryUI

@onready var interaction_field: InteractionField = $InteractionField
@onready var inventory: Inventory = $Inventory
@onready var interact_popup: InteractPopup = %InteractPopup

var input_state: InputState


func _ready() -> void:
	# Only enable camera for the local player
	$Camera2D.enabled = is_multiplayer_authority()
	inventory.item_updated.connect(inventory_ui._handle_item_updated)


func _physics_process(delta):
	# Remote players will have their position synced via MultiplayerSynchronizer
	if is_multiplayer_authority() && input_state == InputState.WORLD:
		player_movement(delta)


func _input(event: InputEvent) -> void:
	match input_state:
		InputState.WORLD:
			_world_inputs(event)
		InputState.UI:
			_ui_inputs(event)


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


func _world_inputs(event: InputEvent) -> void:
	if event.is_action_pressed("interact") && interaction_field.can_interact():
		var interactable: Interactable = interaction_field.interact(global_position)
		if interactable is WorldItem:
			# add item to inventory
			inventory.add(interactable.item, 1)
			interactable.destroy()
		elif interactable is Campfire && not campfire_ui.connected():
			# open campfire ui
			campfire_ui.open(interactable)
			inventory_ui.open()
			
			input_state = InputState.UI
	elif event.is_action_pressed("open_inventory"):
		inventory_ui.open()
		
		input_state = InputState.UI


func _ui_inputs(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		inventory_ui.close()
		
		if campfire_ui.connected():
			campfire_ui.close()
			
		input_state = InputState.WORLD
	elif event.is_action_pressed("open_inventory") && inventory_ui.visible:
		inventory_ui.close()
		input_state = InputState.WORLD
	elif event.is_action_pressed("ui_accept"):
		if campfire_ui.connected():
			var item = inventory_ui.select_item()
			var burnable = campfire_ui.campfire.add_fuel(item)
		
			if burnable:
				# remove item from inventory
				inventory.remove(item)
		else:
			# offer player feedback to know the item cannot burn
			pass
	elif event.is_action_pressed("ui_left"):
		inventory_ui.prev_item()
	elif event.is_action_pressed("ui_right"):
		inventory_ui.next_item()


func _on_interaction_field_near_interactable() -> void:
	interact_popup.open()

func _on_interaction_field_no_interactables() -> void:
	interact_popup.close()
