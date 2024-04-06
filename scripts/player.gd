class_name Player extends CharacterBody2D

signal torpedo_shot(torpedo)
signal died

@export var acceleration:float= 10.0
@export var max_speed:float= 350.0
@export var rotation_speed:float= 150
@export var trans_length:float= 0.5

@export var warp_multiplier:float = 0.3
@onready var warpm:float = 1

@onready var muzzle = $Muzzle
@onready var sprite = $PlayerSprite

# FIXME:
@onready var asteroid = $"../Asteroids/Asteroid"


@onready var glow_left = $PointLight2D_left
@onready var glow_right = $PointLight2D_right


var torpedo_scene = preload("res://scenes/torpedo.tscn")
var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false
var rate_of_fire = 0.15

var alive := true

func _ready():
	var shieldScene = preload("res://scenes/shield.tscn")
	var newShield = shieldScene.instantiate()
	add_child(newShield)
	
	
	

	
func _process(delta):
	if !alive: return
	
	if Input.is_action_just_pressed("warp"):
		warping_state_change()

	if Input.is_action_pressed("shoot_torpedo"):
		if !shoot_cd:
			shoot_cd = true
			shoot_torpedo()
			await get_tree().create_timer(rate_of_fire).timeout
			shoot_cd = false
			
	if Input.is_action_pressed("shoot_laser"):
		shoot_laser()

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
	if global.warping_active == true: #Not warping
		global.warping_active = false
		create_tween().tween_property(self, "scale", Vector2(1, 1), trans_length)
		warpm = 1
		$Shield.fadein()
		
	elif global.warping_active == false: #Warping
		global.warping_active = true
		create_tween().tween_property(self, "scale", Vector2(1, 1.70), trans_length)
		warpm = warp_multiplier
		$Shield.fadeout()

	
func shoot_torpedo():
	var l = torpedo_scene.instantiate()
	l.global_position = muzzle.global_position
	l.rotation = rotation
	emit_signal("torpedo_shot", l)
	
func shoot_laser():
	var t = laser_scene.instantiate()
	t.global_position = self.global_position

func die(area2D):
	if alive==true:
		alive = false
		self.visible = false
		emit_signal("died")
		print("died")
		

func respawn(pos):
	if alive==false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
