extends Node3D

enum PathType {STRAIGHT, PATH}
@export var path: PathType

var MOVE_SPEED = 150.0
var boost_multiplier = 15
var distanceToCamera:float
var distance_multiplier:float
var volume_factor:float = 1.0


@onready var MovingShips = [%Ent_Kelvin]
@onready var camera = %CharacterBody3D
@onready var engine = %engineSound

func _ready():
	engine.play()

func _process(delta):
	distanceToCamera = MovingShips[0].global_transform.origin.distance_to(camera.global_transform.origin)
	if distanceToCamera > 600:
		distance_multiplier = ((distanceToCamera - 600) / 600 * 0.20) + 1
	else: distance_multiplier = 1.00
	
	
	volume_factor = clamp(-0.007826 * distanceToCamera - 1.8, -12, -3)
	engine.volume_db = volume_factor
	
func _physics_process(delta):
	var current_speed = MOVE_SPEED
	if OS.get_name() == "Windows":
		if Input.is_action_pressed("warp"):
			current_speed *= boost_multiplier
	if OS.get_name() == "Android":
		if Input.is_action_pressed("left_click"):
			current_speed *= boost_multiplier
		
	if path == PathType.STRAIGHT:
		translate(Vector3(0, 0, -current_speed * delta))
	elif path == PathType.PATH:
		self.progress += current_speed * delta * distance_multiplier
