class_name Player extends CharacterBody2D

signal torpedo_shot(torpedo)
signal died
signal warping
signal impulse

@export var acceleration:float= 5
@export var max_speed:float= 400.0
@export var rotation_speed:float= 150
@export var trans_length:float= 0.8

@export var warp_multiplier:float = 0.4
@onready var warpm:float = 1

@onready var muzzle = $Muzzle

@onready var warping_active = false
@onready var shield_active = false

var torpedo_scene = preload("res://scenes/torpedo.tscn")
var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false
var rate_of_fire = 0.2

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
	
	velocity += input_vector.rotated(rotation) * acceleration / warpm
	velocity = velocity.limit_length(max_speed/warpm)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed*delta*warpm))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed*delta*warpm))
	
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)
	
	move_and_slide()

func warping_state_change(): #Reverses warping state
	if warping_active == true: #Transition to impulse
		warping_active = false
		create_tween().tween_property(self, "scale", Vector2(1, 1), trans_length)
		create_tween().tween_property(self, "warpm", 1.0, trans_length)
		#warpm = 1
		$Shield.fadein()
		warping.emit()
		
	elif warping_active == false: #Transition to warp
		warping_active = true
		create_tween().tween_property(self, "scale", Vector2(1, 1.70), trans_length)
		create_tween().tween_property(self, "warpm", warp_multiplier, trans_length)
		$Shield.fadeout()
		impulse.emit()

	
func shoot_torpedo():
	var t = torpedo_scene.instantiate()
	t.global_position = muzzle.global_position
	t.rotation = rotation
	emit_signal("torpedo_shot", t)
	
func shoot_laser():
	var l = laser_scene.instantiate()
	l.global_position = self.global_position

func die(area2D): # Recieves a connect from 
	if area2D.is_in_group("player") or area2D.is_in_group("shield"):
		if alive == true:
			alive = false
			self.visible = false
			emit_signal("died") # Connected to "_on_player_died()" in game.gd

func respawn(pos):
	if alive==false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
