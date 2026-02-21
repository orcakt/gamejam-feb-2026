class_name Player
extends CharacterBody2D


enum InputState {
	WORLD,
	UI
}

const SPEED = 100.0
const FOOTSTEP_DISTANCE := 40.0
const FOOTSTEP_VARIATIONS := 6
const FOOTSTEP_PITCH_MIN := 0.9
const FOOTSTEP_PITCH_MAX := 1.1
const FOOTSTEP_SURFACES: Array[String] = ["grass", "dirt", "water"]

var _footstep_accum: float = 0.0

@onready var sound_pool: SoundPool = $SoundPool
@export var crafting_ui: CraftingUI
@export var campfire_ui: CampfireUI
@export var inventory_ui: InventoryUI

@onready var interaction_field: InteractionField = $InteractionField
@onready var crafter: Crafter = $Crafter
@onready var inventory: Inventory = $Inventory
@onready var interact_popup: InteractPopup = %InteractPopup
@onready var item_placement: ItemPlacement = %ItemPlacement
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


var input_state: InputState


func _ready() -> void:
	# Only enable camera for the local player
	$Camera2D.enabled = is_multiplayer_authority()
	inventory.item_updated.connect(inventory_ui._handle_item_updated)
	
	# setup crafter
	crafting_ui.crafter = crafter
	crafting_ui.inventory = inventory


func _physics_process(delta):
	# Remote players will have their position synced via MultiplayerSynchronizer
	if is_multiplayer_authority() && input_state == InputState.WORLD:
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		player_movement(direction)
		item_placement.face(direction)
		
		play_anim(direction)
		_update_footsteps(delta)


func _update_footsteps(delta: float) -> void:
	if velocity.length() < 1.0:
		return
	_footstep_accum += velocity.length() * delta
	if _footstep_accum < FOOTSTEP_DISTANCE:
		return
	_footstep_accum = fmod(_footstep_accum, FOOTSTEP_DISTANCE)
	
	var surface := SpatialSense.describe_tile_at(global_position)
	if surface not in FOOTSTEP_SURFACES:
		return
	
	var variation := randi_range(1, FOOTSTEP_VARIATIONS)
	var path := "res://assets/sfx/steps/%s/%d.wav" % [surface, variation]
	var pitch := randf_range(FOOTSTEP_PITCH_MIN, FOOTSTEP_PITCH_MAX)
	sound_pool.play(path, pitch)


func _input(event: InputEvent) -> void:
	match input_state:
		InputState.WORLD:
			_world_inputs(event)
		InputState.UI:
			_ui_inputs(event)


func player_movement(direction: Vector2) -> void:
	velocity = direction * SPEED
	move_and_slide()


func play_anim(direction: Vector2) -> void:
	match direction:
		Vector2.RIGHT:
			animated_sprite.flip_h = false
			animated_sprite.play("walk_side")
		Vector2.LEFT:
			animated_sprite.flip_h = true
			animated_sprite.play("walk_side")
		Vector2.DOWN:
			animated_sprite.play("walk_down")
		Vector2.UP:
			animated_sprite.play("walk_up")
		Vector2.ZERO:
			animated_sprite.play("idle")


func scan_surroundings() -> Dictionary:
	var desc := {}
	var ray_nodes := {
		"north": $RayCasts/North, "northeast": $RayCasts/NorthEast,
		"east": $RayCasts/East,   "southeast": $RayCasts/SouthEast,
		"south": $RayCasts/South, "southwest": $RayCasts/SouthWest,
		"west": $RayCasts/West,   "northwest": $RayCasts/NorthWest,
	}
	for dir_name in ray_nodes:
		var rc: RayCast2D = ray_nodes[dir_name]
		if rc.is_colliding():
			var surface := SpatialSense.describe_tile_at(rc.get_collision_point())
			desc[dir_name] = surface if surface != "" else rc.get_collider().name
		else:
			desc[dir_name] = "open"
	return desc


func get_facing_ray() -> RayCast2D:
	var dir_name := SpatialSense.velocity_to_direction_name(velocity)
	var map := {
		"north": $RayCasts/North, "northeast": $RayCasts/NorthEast,
		"east": $RayCasts/East,   "southeast": $RayCasts/SouthEast,
		"south": $RayCasts/South, "southwest": $RayCasts/SouthWest,
		"west": $RayCasts/West,   "northwest": $RayCasts/NorthWest,
	}
	return map.get(dir_name, $RayCasts/South)


func _world_inputs(event: InputEvent) -> void:
	if event.is_action_pressed("interact") && item_placement.is_holding():
		var item = item_placement.release()
		inventory.remove(item)
	elif event.is_action_pressed("ui_cancel") && item_placement.is_holding():
		item_placement.cancel()
	elif event.is_action_pressed("interact") && interaction_field.can_interact():
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
	elif event.is_action_pressed("open_crafting_menu"):
		crafting_ui.open()
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
	elif event.is_action_pressed("craft_item") && crafting_ui.visible:
		crafting_ui.try_craft()
	elif event.is_action_pressed("open_crafting_menu") && crafting_ui.visible:
		crafting_ui.close()
		inventory_ui.close()
		input_state = InputState.WORLD
	elif event.is_action_pressed("open_inventory") && inventory_ui.visible:
		inventory_ui.close()
		input_state = InputState.WORLD
	elif event.is_action_pressed("interact") && campfire_ui.connected():
		campfire_ui.close()
		inventory_ui.close()
		input_state = InputState.WORLD
	elif event.is_action_pressed("ui_accept"):
		var item = inventory_ui.select_item()
		
		if campfire_ui.connected() && item.burnable:
			# use item as fuel
			campfire_ui.campfire.add_fuel(item)
			inventory.remove(item)
		elif item.placeable:
			# allow player to place item where they want
			item_placement.hold(item)
			inventory_ui.close()
			input_state = InputState.WORLD
	elif event.is_action_pressed("ui_right") && crafting_ui.visible:
		crafting_ui.focus_next()
	elif event.is_action_pressed("ui_left") && crafting_ui.visible:
		crafting_ui.focus_prev()
	elif event.is_action_pressed("ui_right"):
		inventory_ui.next_item()
	elif event.is_action_pressed("ui_left"):
		inventory_ui.prev_item()


func _on_interaction_field_near_interactable() -> void:
	interact_popup.open()

func _on_interaction_field_no_interactables() -> void:
	interact_popup.close()


# spatial sense debug hotkey — announces surroundings via screen reader
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		var facing := SpatialSense.velocity_to_direction_name(velocity)
		var tile := SpatialSense.query_tile_at(global_position)
		var surface := tile.surface_type if tile.found and tile.surface_type != "" else "unknown"

		var parts: Array[String] = []
		parts.append("Position: %d, %d" % [roundi(global_position.x), roundi(global_position.y)])
		parts.append("Facing: %s" % facing)
		parts.append("Surface: %s" % surface)

		var scan := scan_surroundings()
		var obstacles: Array[String] = []
		for dir: String in ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"]:
			if scan[dir] != "open":
				obstacles.append("%s: %s" % [dir, scan[dir]])
		if obstacles.is_empty():
			parts.append("Surroundings: open")
		else:
			parts.append("Obstacles: " + ", ".join(obstacles))

		var nearby := SpatialSense.get_nodes_in_radius(global_position, 200.0, 4, [get_rid()])
		if not nearby.is_empty():
			var node_parts: Array[String] = []
			for r: SpatialSense.NodeQueryResult in nearby:
				node_parts.append("%s to the %s at %d pixels" % [r.node_name, r.direction, roundi(r.distance)])
			parts.append("Nearby: " + ", ".join(node_parts))

		ScreenReader.speak(". ".join(parts))
