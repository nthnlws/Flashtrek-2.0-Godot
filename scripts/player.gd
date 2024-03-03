class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died
signal is_warping

@export var acceleration := 10.0
@export var max_speed := 350.0
@export var rotation_speed := 250.0

@export var warping := false
@export var warp_multiplier := 1.0

@export var warpmax_speed := 600.0
@export var warpRotation_speed := 110.0


@onready var muzzle = $Muzzle
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

@onready var glow_left = $PointLight2D_left
@onready var glow_right = $PointLight2D_right
@onready var playersprite = $Sprite2D
@onready var collision = $CollisionShape2D

#func warp_input():

var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false
var rate_of_fire = 0.15

var alive := true

func _process(delta):
	if !alive: return
	
	if Input.is_action_just_pressed("warp"):
		if warping == true:
			warping = false
		elif warping == false:
			warping = true
			
	if warping == true:
		warp_multiplier = 0.3
		playersprite.scale.y = 1.05
		collision.scale.y = 1.05
	elif warping == false:
		warp_multiplier = 1
		playersprite.scale.y = 0.6
		collision.scale.y = 0.6
			
	if Input.is_action_pressed("shoot"):
		if !shoot_cd:
			shoot_cd = true
			shoot_laser()
			await get_tree().create_timer(rate_of_fire).timeout
			shoot_cd = false

func _physics_process(delta):
	if !alive: return
	
	var input_vector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	velocity += input_vector.rotated(rotation) * acceleration
	velocity = velocity.limit_length(max_speed/warp_multiplier)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed*delta*warp_multiplier))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed*delta*warp_multiplier))
	
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)
	
	move_and_slide()

func shoot_laser():
	var l = laser_scene.instantiate()
	l.global_position = muzzle.global_position
	l.rotation = rotation
	emit_signal("laser_shot", l)

func die():
	if alive==true:
		alive = false
		sprite.visible = false
		glow_right.visible = false
		glow_left.visible = false
		cshape.set_deferred("disabled", true)
		warping = false
		emit_signal("died")
		

func respawn(pos):
	if alive==false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		sprite.visible = true
		warp_multiplier = 1
		cshape.set_deferred("disabled", false)
