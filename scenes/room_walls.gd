extends Node2D

var WallScene = preload("res://scenes/border_wall.tscn")
var borderCoords:int = 20000

var wall_positions = [
	Vector2(0, borderCoords),
	Vector2(0, -borderCoords),
	Vector2(borderCoords, 0),
	Vector2(-borderCoords, 0)
]

var wall_scales = [
	Vector2(borderCoords/233/2, 0.3),
	Vector2(borderCoords/233/2, 0.3),
	Vector2(borderCoords/233/2, 0.3),
	Vector2(borderCoords/233/2, 0.3),
]

var wall_rotations = [
	0,				# No rotation
	PI / 2,			# 90 degrees
	PI / 1, 		# 180 degrees
	3 * PI / 2		# 270 degrees
]

func _ready():
	for i in range(len(wall_positions)):
		var wall_instance = WallScene.instantiate()
		wall_instance.position = wall_positions[i]
		wall_instance.scale = wall_scales[i]
		wall_instance.rotation = wall_rotations[i]
		add_child(wall_instance)
