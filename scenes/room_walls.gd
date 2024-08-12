extends Node2D

var WallScene = preload("res://scenes/border_wall.tscn")
@export var borderCoords:float = 10000

var wall_positions = [
	Vector2(0, borderCoords),
	Vector2(0, -borderCoords),
	Vector2(borderCoords, 0),
	Vector2(-borderCoords, 0)
]

var wall_scales = [
	Vector2((borderCoords/233*2)*1.01, 1),
	Vector2((borderCoords/233*2)*1.01, 1),
	Vector2((borderCoords/233*2)*1.01, 1),
	Vector2((borderCoords/233*2)*1.01, 1),
]

var wall_names = [
	"North_wall",
	"South_wall",
	"East_wall",
	"West_wall",
]

var wall_rotations = [
	0,				# No rotation
	PI,				# 180 Degrees
	3 * PI / 2,		# 270 Degrees
	PI / 2			# 90 degrees
]

func _ready():
	Global.levelBorders = self
	GameSettings.gameSize = borderCoords
	for i in range(len(wall_positions)):
		var wall_instance = WallScene.instantiate()
		wall_instance.position = wall_positions[i]
		wall_instance.rotation = wall_rotations[i]
		wall_instance.name = wall_names[i]
		add_child(wall_instance)
		
		#Scale Sprite
		var sprite = wall_instance.get_node("Barrier")
		sprite.scale = wall_scales[i]
		
		# Create a label for the wall
		var label = Label.new()
		label.text = wall_names[i]
		add_child(label)

		# Position the label near the wall
		label.position = wall_positions[i] + Vector2(10, 10) # Adjust this offset as needed
		label.scale = Vector2(2, 2) # Makes the label larger and easier to see
