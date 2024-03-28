class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died

@export var acceleration:float= 10.0
@export var max_speed:float= 350.0
@export var rotation_speed:float= 150

@export var warp_multiplier:float = 0.3
@onready var warpm:float = 1

@onready var muzzle = $Muzzle
@onready var sprite = $PlayerSprite
@onready var shield = $Shield
@onready var cshape = $CollisionPolygon2D

@onready var glow_left = $PointLight2D_left
@onready var glow_right = $PointLight2D_right
@onready var collision = $CollisionPolygon2D


var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false
var rate_of_fire = 0.15

var alive := true

func _ready():
	pass
	
func _process(delta):
	if !alive: return
	
	if Input.is_action_just_pressed("warp"):
		warping_state_change()

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
	velocity = velocity.limit_length(max_speed/warpm)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed*delta*warpm))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed*delta*warpm))
	
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)
	
	move_and_slide()

# Reverses warping state and all associated properties
func warping_state_change():
	if global.warping_active == true:
		global.warping_active = false
		create_tween().tween_property(self, "scale", Vector2(1, 1), 0.5)
		warpm = 1
	elif global.warping_active == false:
		global.warping_active = true
		create_tween().tween_property(self, "scale", Vector2(1, 1.75), 0.5)
		warpm = warp_multiplier

func shoot_laser():
	var l = laser_scene.instantiate()
	l.global_position = muzzle.global_position
	l.rotation = rotation
	emit_signal("laser_shot", l)

func die():
	if alive==true:
		alive = false
		sprite.visible = false
		shield.visible = false
		glow_right.visible = false
		glow_left.visible = false
		cshape.set_deferred("disabled", true)
		emit_signal("died")
		

func respawn(pos):
	if alive==false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		sprite.visible = true
		shield.visible = true
		cshape.set_deferred("disabled", false)
