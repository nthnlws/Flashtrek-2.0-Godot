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
	Vector2(((borderCoords+23.5)/233*2), 1),
	Vector2(((borderCoords+23.5)/233*2), 1),
	Vector2(((borderCoords-23.5)/233*2), 1),
	Vector2(((borderCoords-23.5)/233*2), 1),
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
	Global.levelWalls.clear()
	Global.levelBorderNode = self
	
	if GameSettings.loadNumber == 0:
		GameSettings.gameSize = borderCoords
	elif GameSettings.loadNumber > 0:
		_on_border_coords_moved()

	for i in range(len(wall_positions)):
		var wall_instance = WallScene.instantiate()
		wall_instance.position = wall_positions[i]
		wall_instance.rotation = wall_rotations[i]
		wall_instance.name = wall_names[i]
		wall_instance.scale = wall_scales[i]
		if GameSettings.noCollision == true:
				wall_instance.get_node("WorldBoundary").disabled = true
		add_child(wall_instance)
		
		## Create a label for the wall
		#var label = Label.new()
		#label.text = wall_names[i]
		#add_child(label)
#
		## Position the label near the wall
		#label.position = wall_positions[i] + Vector2(10, 10) # Adjust this offset as needed
		#label.scale = Vector2(2, 2) # Makes the label larger and easier to see
		
		Global.levelWalls.append(wall_instance)
		
func _on_border_coords_moved():
	wall_positions = [
	Vector2(0, GameSettings.gameSize),
	Vector2(0, -GameSettings.gameSize),
	Vector2(GameSettings.gameSize, 0),
	Vector2(-GameSettings.gameSize, 0)
]
	wall_scales = [
	Vector2(((GameSettings.gameSize+23.5)/233*2), 1),
	Vector2(((GameSettings.gameSize+23.5)/233*2), 1),
	Vector2(((GameSettings.gameSize-23.5)/233*2), 1),
	Vector2(((GameSettings.gameSize-23.5)/233*2), 1),
]
	for i in range(Global.levelWalls.size()):
		var wall = Global.levelWalls[i]
		if is_instance_valid(wall):
			wall.position = wall_positions[i]
			wall.scale = wall_scales[i]

func _on_collision_changed(toggle_status):
	for i in range(Global.levelWalls.size()):
		var wall = Global.levelWalls[i]
		if is_instance_valid(wall):
			wall.get_node("WorldBoundary").disabled = toggle_status
