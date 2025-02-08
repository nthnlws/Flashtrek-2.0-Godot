extends Node2D

@export var WallScene: PackedScene
@export var defaultBorderCoords:int = 20000
var borderCoords:int = defaultBorderCoords

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
	deg_to_rad(0),		# No rotation
	deg_to_rad(180),	# 180 Degrees
	deg_to_rad(270),	# 270 Degrees
	deg_to_rad(90)		# 90 degrees
]

func _ready():
	SignalBus.entering_galaxy_warp.connect(fade_world_borders)
	
	
	if GameSettings.borderToggle == true:
		borderCoords = GameSettings.borderValue
	else: borderCoords = defaultBorderCoords
	
	Utility.mainScene.levelWalls.clear()

	SignalBus.border_size_moved.connect(_on_border_coords_moved)
	SignalBus.collisionChanged.connect(_on_collision_changed)
	
	if GameSettings.loadNumber == 0:
		GameSettings.borderValue = borderCoords
	elif GameSettings.loadNumber > 0:
		_on_border_coords_moved()

	for i in range(len(wall_positions)):
		var wall_instance = WallScene.instantiate()
		wall_instance.position = wall_positions[i]
		wall_instance.add_to_group("borders")
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
		
		Utility.mainScene.levelWalls.append(wall_instance)
		
func _on_border_coords_moved():
	wall_positions = [
	Vector2(0, GameSettings.borderValue),
	Vector2(0, -GameSettings.borderValue),
	Vector2(GameSettings.borderValue, 0),
	Vector2(-GameSettings.borderValue, 0)
]
	wall_scales = [
	Vector2(((GameSettings.borderValue+23.5)/233*2), 1),
	Vector2(((GameSettings.borderValue+23.5)/233*2), 1),
	Vector2(((GameSettings.borderValue-23.5)/233*2), 1),
	Vector2(((GameSettings.borderValue-23.5)/233*2), 1),
]
	for i in range(Utility.mainScene.levelWalls.size()):
		var wall = Utility.mainScene.levelWalls[i]
		if is_instance_valid(wall):
			wall.position = wall_positions[i]
			wall.scale = wall_scales[i]

func _on_collision_changed(toggle_status):
	for i in range(Utility.mainScene.levelWalls.size()):
		var wall = Utility.mainScene.levelWalls[i]
		if is_instance_valid(wall):
			wall.get_node("WorldBoundary").disabled = toggle_status


func fade_world_borders():
	for bord in get_tree().get_nodes_in_group("borders"):
		bord.get_node("WorldBoundary").disabled = true
		await get_tree().create_timer(0.3).timeout
		if Utility.mainScene.in_galaxy_warp == true:
			create_tween().tween_property(bord, "modulate", Color(1, 1, 1, 0), 0.8)
