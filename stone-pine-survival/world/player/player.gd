extends CharacterBody2D


const SPEED = 100.0


func _ready() -> void:
	# Only enable camera for the local player
	$Camera2D.enabled = is_multiplayer_authority()


func _physics_process(delta):
	# Remote players will have their position synced via MultiplayerSynchronizer
	if is_multiplayer_authority():
		player_movement(delta)


func player_movement(delta):
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
