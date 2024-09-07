extends Node2D

@onready var sprite = $SunTexture

@export var radius = 4500


func _ready():
	rotation_degrees = 20
	
	var random_index = "%02d" % randi_range(1, 6)
	var sprite_path = "res://assets/textures/suns/sun_%s.png" % random_index
	sprite.texture = load(sprite_path)
	
	var angle = randf_range(0, TAU) # 0-360 degrees
	var sun_position = Vector2(cos(angle), sin(angle)) * radius
	position = sun_position
	LevelData.suns.append(self)


	
func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)
