class_name SpawnZone
extends Area2D

const WORLD_ITEM_SCENE := preload("res://world/items/world_item.tscn")

@export_group("Spawn Entries")
@export var spawn_entries: Array[SpawnEntry] = []

@export_group("Population")
@export var max_items: int = 5
@export var initial_spawn_count: int = 3

@export_group("Respawn")
@export var respawn_enabled: bool = true
@export var respawn_interval: float = 30.0

@export_group("Placement")
@export var min_spacing: float = 24.0
@export var max_placement_attempts: int = 20

var _spawned_items: Array[WorldItem] = []


func _ready() -> void:
	# Serveronly or singleplayer spawning
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	if spawn_entries.is_empty():
		push_warning("SpawnZone '%s': spawn_entries is empty." % name)
		return

	if _get_collision_shape() == null:
		push_warning("SpawnZone '%s': no CollisionShape2D found." % name)
		return

	for i in mini(initial_spawn_count, max_items):
		_try_spawn_item()


# Connected in .tscn to Area2D body_exited signal
func _on_body_exited(body: Node2D) -> void:
	if body is WorldItem and body in _spawned_items:
		_spawned_items.erase(body)
		if respawn_enabled:
			get_tree().create_timer(respawn_interval).timeout.connect(_on_respawn_timer)


func _on_respawn_timer() -> void:
	if _spawned_items.size() < max_items:
		_try_spawn_item()


func _try_spawn_item() -> void:
	if _spawned_items.size() >= max_items:
		return
	var entry := _pick_weighted_entry()
	if entry == null or entry.item == null:
		return
	var shape := _get_collision_shape()
	if shape == null:
		return
	var pos := _find_valid_position(shape)
	if pos == Vector2.INF:
		push_warning("SpawnZone '%s': could not place item after %d attempts." % [name, max_placement_attempts])
		return
	var world_item: WorldItem = WORLD_ITEM_SCENE.instantiate()
	world_item.item = entry.item
	world_item.position = pos
	add_child(world_item)
	world_item.setup()
	_spawned_items.append(world_item)


func _find_valid_position(shape_node: CollisionShape2D) -> Vector2:
	for _i in max_placement_attempts:
		var candidate := _random_point_in_shape(shape_node.shape, shape_node.global_position)
		if not _is_too_close(candidate):
			return to_local(candidate)
	return Vector2.INF


func _random_point_in_shape(shape: Shape2D, origin: Vector2) -> Vector2:
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size / 2.0
		return origin + Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius * sqrt(randf())
		var a := randf() * TAU
		return origin + Vector2(cos(a), sin(a)) * r
	else:
		var b := shape.get_rect()
		return origin + Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))


func _is_too_close(candidate: Vector2) -> bool:
	for item in _spawned_items:
		if is_instance_valid(item) and item.global_position.distance_to(candidate) < min_spacing:
			return true
	return false


func _pick_weighted_entry() -> SpawnEntry:
	var total := 0.0
	for e: SpawnEntry in spawn_entries:
		if e != null:
			total += e.weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	var cumul := 0.0
	for e: SpawnEntry in spawn_entries:
		if e == null:
			continue
		cumul += e.weight
		if roll <= cumul:
			return e
	return spawn_entries.back()


func _get_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null
