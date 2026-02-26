extends Node

@onready var health_bar: ProgressBar = $CanvasLayer/Health
@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var hunger_bar: ProgressBar = $CanvasLayer/Hunger
@onready var thirst_bar: ProgressBar = $CanvasLayer/Thirst

@export var health_drain_speed: float = 0
@export var energy_drain_speed: float = 0.25
@export var hunger_drain_speed: float = 1
@export var thirst_drain_speed: float = 1.5
@export var final_energy_drain_speed: float = 0.25

var health = 100
var energy = 100
var hunger = 100
var thirst = 100
var max_stat = 100

func setup_stats() -> void:
	health_bar.max_value = max_stat
	health_bar.value = health
	
	energy_bar.max_value = max_stat
	energy_bar.value = energy
	
	hunger_bar.max_value = max_stat
	hunger_bar.value = hunger
	
	thirst_bar.max_value = max_stat
	thirst_bar.value = thirst

func _process(delta: float):
	health -= (health_drain_speed * delta)/10
	health_bar.value = health
	energy -= (energy_drain_speed * delta)/10
	energy_bar.value = energy
	hunger -= (hunger_drain_speed * delta)/10
	hunger_bar.value = hunger
	thirst -= (thirst_drain_speed * delta)/10
	thirst_bar.value = thirst
	
	if(hunger < 1 || thirst < 1):
		energy_deplete()
	if(hunger < 1 || thirst < 1 || energy < 1):
		health_drain_speed += 0.002

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_W):
		restore_thirst(20)

func take_damage(amount):
	health -= amount
	health = clamp(health, 0, max_stat)
	health_bar.value = health

func restore_health(amount):
	health += amount
	health = clamp(health, 0, max_stat)
	health_bar.value = health

func restore_energy(amount):
	energy += amount
	energy = clamp(energy, 0, max_stat)
	energy_bar.value = energy

func restore_hunger(amount):
	if hunger == 0:
		slow_energy_deplete()
	hunger += amount
	hunger = clamp(hunger, 0, max_stat)
	hunger_bar.value = hunger
	
func restore_thirst(amount):
	thirst += amount
	thirst = clamp(thirst, 0, max_stat)
	thirst_bar.value = thirst

func energy_deplete():
	if hunger < 1:
		energy_drain_speed += 0.001
	if thirst < 1:
		energy_drain_speed += 0.002

func slow_energy_deplete():
	energy_drain_speed = final_energy_drain_speed
