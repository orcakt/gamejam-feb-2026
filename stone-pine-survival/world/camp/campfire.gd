class_name Campfire
extends Interactable


enum Levels {
	DEAD,
	SMOLDER,
	FLAME,
}

const MOD: int = 4

@export_category("Animations")
@export var frames_per_second: int = 12

@export_category("Mechanics")
@export var fuel_loss_per_second: float = 0.3
@export var fuel_types: Dictionary[Item, int]
@export var level_amounts: Dictionary[Levels, int]

@onready var sprite: Sprite2D = $Sprite2D

var current_level: Levels
var current_frame: int
var current_fuel: float


func add_fuel(item: Item) -> void:
	# increase fuel amount per item
	current_fuel += fuel_types[item]
	
	# set the appropriate level
	_set_level()


func _process(delta: float) -> void:
	_burn_fuel(delta)
	_animate()


func _burn_fuel(delta: float) -> void:
	# slowly decrease
	current_fuel -= fuel_loss_per_second * delta
	if current_fuel < 0:
		current_fuel = 0
	
	# update level if needed
	_set_level()


func _animate() -> void:
	match current_level:
		Levels.SMOLDER:
			current_frame = (current_frame + 1) % frames_per_second
			if current_frame == 0:
				sprite.frame = (sprite.frame + 1) % MOD
		Levels.FLAME:
			current_frame = (current_frame + 1) % frames_per_second
			if current_frame == 0:
				sprite.frame = (sprite.frame + 1) % MOD + 4
		Levels.DEAD:
			pass


func _set_level() -> void:
	if current_fuel < level_amounts[Levels.SMOLDER]:
		sprite.frame = 8
		current_level = Levels.DEAD
	elif level_amounts[Levels.SMOLDER] < current_fuel && current_fuel < level_amounts[Levels.FLAME]:
		current_level = Levels.SMOLDER
	elif level_amounts[Levels.FLAME] < current_fuel:
		current_level = Levels.FLAME


func _increment() -> void:
	match current_level:
		Levels.DEAD:
			current_level = Levels.SMOLDER
		Levels.SMOLDER:
			current_level = Levels.FLAME
		Levels.FLAME:
			# do nothing
			pass


func _decrement() -> void:
	match current_level:
		Levels.DEAD:
			# do nothing
			pass
		Levels.SMOLDER:
			current_frame = 0
			sprite.frame = 8
			current_level = Levels.DEAD
		Levels.FLAME:
			current_level = Levels.SMOLDER
