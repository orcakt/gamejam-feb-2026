extends Node

class NodeQueryResult:
	var found: bool
	var node: Node2D
	var world_pos: Vector2
	var distance: float
	var direction: String
	var node_name: String

	func _init() -> void:
		found = false
		node = null
		world_pos = Vector2.ZERO
		distance = 0.0
		direction = ""
		node_name = ""


class TileQueryResult:
	var found: bool
	var world_pos: Vector2
	var map_coords: Vector2i
	var surface_type: String
	var tile_name: String
	var is_passable: bool
	var layer_name: String

	func _init() -> void:
		found = false
		world_pos = Vector2.ZERO
		map_coords = Vector2i.ZERO
		surface_type = ""
		tile_name = ""
		is_passable = true
		layer_name = ""


# Internal State

var _layer_base: TileMapLayer
var _layer_decoration: TileMapLayer
var _layer_physics_a: TileMapLayer
var _layer_physics_b: TileMapLayer

const DIRECTION_VECTORS := {
	"north": Vector2(0, -1),
	"northeast": Vector2(0.707, -0.707),
	"east": Vector2(1, 0),
	"southeast": Vector2(0.707, 0.707),
	"south": Vector2(0, 1),
	"southwest": Vector2(-0.707, 0.707),
	"west": Vector2(-1, 0),
	"northwest": Vector2(-0.707, -0.707),
	"none": Vector2.ZERO,
}



func register_tilemap_layers(
	base: TileMapLayer,
	decoration: TileMapLayer,
	physics_a: TileMapLayer,
	physics_b: TileMapLayer
) -> void:
	_layer_base = base
	_layer_decoration = decoration
	_layer_physics_a = physics_a
	_layer_physics_b = physics_b


func velocity_to_direction_name(velocity: Vector2) -> String:
	if velocity.length_squared() < 0.001:
		return "none"
	return vector_to_nearest_direction_name(velocity.normalized())


func direction_name_to_vector(name: String) -> Vector2:
	return DIRECTION_VECTORS.get(name, Vector2.ZERO)


func vector_to_nearest_direction_name(vec: Vector2) -> String:
	if vec.length_squared() < 0.001:
		return "none"
	var best_name := "none"
	var best_dot := -INF
	for dir_name in DIRECTION_VECTORS:
		if dir_name == "none":
			continue
		var dot := vec.normalized().dot(DIRECTION_VECTORS[dir_name])
		if dot > best_dot:
			best_dot = dot
			best_name = dir_name
	return best_name


func _sample_layer(world_pos: Vector2, layer: TileMapLayer, layer_name: String) -> TileQueryResult:
	var result := TileQueryResult.new()
	result.world_pos = world_pos
	result.layer_name = layer_name

	if not is_instance_valid(layer):
		return result

	var map_coords := layer.local_to_map(layer.to_local(world_pos))
	result.map_coords = map_coords

	var tile_data := layer.get_cell_tile_data(map_coords)
	if tile_data == null:
		return result

	result.found = true
	var st = tile_data.get_custom_data("surface_type")
	result.surface_type = st if st != null else ""
	var tn = tile_data.get_custom_data("tile_name")
	result.tile_name = tn if tn != null else ""
	var passable = tile_data.get_custom_data("passable")
	result.is_passable = passable if passable != null else true

	return result


func query_tile_at(world_pos: Vector2) -> TileQueryResult:
	# Priority: physics_b -> physics_a -> decoration -> base
	for pair in [
		[_layer_physics_b, "physics_b"],
		[_layer_physics_a, "physics_a"],
		[_layer_decoration, "decoration"],
		[_layer_base, "base"],
	]:
		var r := _sample_layer(world_pos, pair[0], pair[1])
		if r.found:
			return r

	var empty := TileQueryResult.new()
	empty.world_pos = world_pos
	return empty


func query_tile_layer(world_pos: Vector2, layer: String) -> TileQueryResult:
	var target: TileMapLayer
	match layer:
		"base":        target = _layer_base
		"decoration":  target = _layer_decoration
		"physics_a":   target = _layer_physics_a
		"physics_b":   target = _layer_physics_b
		_:
			var empty := TileQueryResult.new()
			empty.world_pos = world_pos
			return empty
	return _sample_layer(world_pos, target, layer)


func describe_tile_at(world_pos: Vector2) -> String:
	var r := query_tile_at(world_pos)
	if r.found and r.surface_type != "":
		return r.surface_type
	return ""


func scan_nodes_in_direction(
	from_pos: Vector2,
	direction: String,
	max_distance: float = 300.0,
	collision_mask: int = 0xFFFFFFFF,
	exclude: Array[RID] = []
) -> NodeQueryResult:
	var result := NodeQueryResult.new()
	result.direction = direction

	var dir_vec := direction_name_to_vector(direction)
	if dir_vec == Vector2.ZERO:
		return result

	var space_state := get_viewport().find_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		from_pos,
		from_pos + dir_vec * max_distance,
		collision_mask,
		exclude
	)
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return result

	result.found = true
	result.world_pos = hit["position"]
	result.distance = from_pos.distance_to(hit["position"])
	var collider = hit["collider"]
	if collider is Node2D:
		result.node = collider
		result.node_name = collider.name
	return result


func scan_nodes_all_directions(
	from_pos: Vector2,
	max_distance: float = 300.0,
	collision_mask: int = 0xFFFFFFFF,
	exclude: Array[RID] = []
) -> Dictionary:
	var results := {}
	for dir_name in DIRECTION_VECTORS:
		if dir_name == "none":
			continue
		results[dir_name] = scan_nodes_in_direction(from_pos, dir_name, max_distance, collision_mask, exclude)
	return results


func get_nodes_in_radius(
	from_pos: Vector2,
	radius: float = 200.0,
	collision_mask: int = 0xFFFFFFFF,
	exclude: Array[RID] = []
) -> Array:
	var space_state := get_viewport().find_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, from_pos)
	query.collision_mask = collision_mask
	query.exclude = exclude

	var hits := space_state.intersect_shape(query, 32)

	var results: Array = []
	for hit in hits:
		var r := NodeQueryResult.new()
		r.found = true
		var collider = hit["collider"]
		if collider is Node2D:
			r.node = collider
			r.node_name = collider.name
			r.world_pos = collider.global_position
		else:
			r.world_pos = from_pos
		r.distance = from_pos.distance_to(r.world_pos)
		var to_node := (r.world_pos - from_pos)
		r.direction = vector_to_nearest_direction_name(to_node)
		results.append(r)

	results.sort_custom(func(a, b): return a.distance < b.distance)
	return results
