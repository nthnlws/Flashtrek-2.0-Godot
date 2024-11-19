extends Node2D

@onready var sprite = $SunTexture

@export var spawnDistance = 4250
@export var spawnVariability = 300


func _ready():
	spawnDistance = randi() % (2 * spawnVariability + 1) - spawnVariability + spawnDistance
	rotation_degrees = 20
	
	var random_index = randi_range(0, 5)
	sprite.frame = random_index
	
	var angle = randf_range(0, TAU) # 0-360 degrees
	var sun_position = Vector2(cos(angle), sin(angle)) * spawnDistance
	position = sun_position
	Utility.mainScene.suns.append(self)


func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)
