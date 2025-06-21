extends Node3D

enum PathType {STRAIGHT, PATH}
@export var path: PathType

var MOVE_SPEED: float = 150.0
var boost_multiplier: int = 15
var distanceToCamera:float
var distance_multiplier:float
var volume_factor:float = 1.0


@onready var MovingShips: Array[Node3D] = [%Ent_Kelvin]
@onready var camera: Camera3D = %Camera3D
@onready var engine: AudioStreamPlayer = %engineSound

func _ready() -> void:
	engine.play()

func _process(delta: float) -> void:
	distanceToCamera = MovingShips[0].global_transform.origin.distance_to(camera.global_transform.origin)
	if distanceToCamera > 600:
		distance_multiplier = ((distanceToCamera - 600) / 600 * 0.20) + 1
	else: distance_multiplier = 1.00
	
	
	volume_factor = clamp(-0.007826 * distanceToCamera - 1.8, -12, -3)
	engine.volume_db = volume_factor
	
func _physics_process(delta: float) -> void:
	var current_speed: float = MOVE_SPEED
	if OS.get_name() == "Windows":
		if Input.is_action_pressed("overdrive"):
			current_speed *= boost_multiplier
	if OS.get_name() == "Android":
		if Input.is_action_pressed("left_click"):
			current_speed *= boost_multiplier
		
	if path == PathType.STRAIGHT:
		translate(Vector3(0, 0, -current_speed * delta))
	elif path == PathType.PATH:
		self.progress += current_speed * delta * distance_multiplier
