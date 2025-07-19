extends Node2D

@export var defaultBorderCoords:int = 20000
var borderCoords:int = defaultBorderCoords

var wall_positions: Array = [
	Vector2(0, borderCoords),
	Vector2(0, -borderCoords),
	Vector2(borderCoords, 0),
	Vector2(-borderCoords, 0)
]

var wall_scales: Array = [
	Vector2(((borderCoords+23.5)/233*2), 1),
	Vector2(((borderCoords+23.5)/233*2), 1),
	Vector2(((borderCoords-23.5)/233*2), 1),
	Vector2(((borderCoords-23.5)/233*2), 1),
]

var wall_rotations: Array = [
	deg_to_rad(0),		# No rotation
	deg_to_rad(180),	# 180 Degrees
	deg_to_rad(270),	# 270 Degrees
	deg_to_rad(90)		# 90 degrees
]

func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(toggle_world_borders)
	SignalBus.entering_new_system.connect(toggle_world_borders)
	
	
	Utility.mainScene.levelWalls.clear()

	SignalBus.border_size_moved.connect(_on_border_coords_moved)
	SignalBus.collisionChanged.connect(_on_collision_changed)
	
	if GameSettings.loadNumber == 0:
		GameSettings.borderValue = borderCoords
	elif GameSettings.loadNumber > 0:
		_on_border_coords_moved()
	
	var i: int = 0
	var borders: Array = get_tree().get_nodes_in_group("borders")
	for wall in borders:
		wall.position = wall_positions[i]
		wall.rotation = wall_rotations[i]
		wall.scale = wall_scales[i]
		if GameSettings.noCollision == true:
				wall.get_node("WorldBoundary").disabled = true
		
		# Create a label for the wall
		var label: Label = Label.new()
		label.text = borders[i].name
		label.add_to_group("Labels")
		add_child(label)

		# Position the label near the wall
		label.position = wall_positions[i] + Vector2(10, 10) # Adjust this offset as needed
		label.scale = Vector2(2, 2) # Makes the label larger and easier to see
		
		SignalBus.level_entity_added.emit(self, "Wall")
		i += 1
		
func _on_border_coords_moved() -> void:
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
		var wall: StaticBody2D  = Utility.mainScene.levelWalls[i]
		if is_instance_valid(wall):
			wall.position = wall_positions[i]
			wall.scale = wall_scales[i]

func _on_collision_changed(toggle_status: bool) -> void:
	for i in range(Utility.mainScene.levelWalls.size()):
		var wall: StaticBody2D = Utility.mainScene.levelWalls[i]
		if is_instance_valid(wall):
			wall.get_node("WorldBoundary").disabled = toggle_status


func toggle_world_borders() -> void:
	for bord in get_tree().get_nodes_in_group("borders"):
		if bord.get_node("WorldBoundary").disabled == false:
			bord.get_node("WorldBoundary").disabled = true
			await get_tree().create_timer(0.3).timeout
			if Utility.mainScene.in_galaxy_warp == true:
				create_tween().tween_property(bord, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
			await get_tree().create_timer(Utility.fadeLength).timeout
		else: 
			bord.get_node("WorldBoundary").disabled = false
			bord.modulate = Color(1, 1, 1, 1)
	for label:Label in get_tree().get_nodes_in_group("Labels"):
		if label.visible:
			label.visible = false
		else:
			label.visible
