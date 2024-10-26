extends Node2D

@onready var sprite = $PlanetTexture

func _ready():
	$AnimatedSprite2D.play()
	rotation = round(deg_to_rad(randi_range(0, 360)))
	rotation_degrees = 40

	
	var random_index = "%03d" % randi_range(1, 221)
	var sprite_path = "res://assets/textures/planets/planet_%s.png" % random_index
	sprite.texture = load(sprite_path)
	
	LevelData.planets.append(self)

func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)
