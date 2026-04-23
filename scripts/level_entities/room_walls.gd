extends Node2D

@export var defaultBorderCoords:int = 20000
var world_size:int = 20000
var active_borders: Array[StaticBody2D] = []

var wall_positions: Array = [
	Vector2(0, world_size),
	Vector2(0, -world_size),
	Vector2(world_size, 0),
	Vector2(-world_size, 0)
]

var wall_scales: Array = [
	Vector2(((world_size+23.5)/233*2), 1),
	Vector2(((world_size+23.5)/233*2), 1),
	Vector2(((world_size-23.5)/233*2), 1),
	Vector2(((world_size-23.5)/233*2), 1),
]

var wall_rotations: Array = [
	deg_to_rad(0),		# No rotation
	deg_to_rad(180),	# 180 Degrees
	deg_to_rad(270),	# 270 Degrees
	deg_to_rad(90)		# 90 degrees
]

func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(toggle_world_borders.bind(false))
	SignalBus.entering_new_system.connect(toggle_world_borders.bind(true))
	
	z_index = Utility.Z["WorldBorders"]
	world_size = LevelManager.current_system_data.system_size

	SignalBus.border_size_moved.connect(_on_border_coords_moved)
	SignalBus.collisionChanged.connect(_on_collision_changed)
	
	var i: int = 0
	for node in get_tree().get_nodes_in_group("borders"):
		active_borders.append(node)
	for wall:StaticBody2D in active_borders:
		wall.position = wall_positions[i]
		wall.rotation = wall_rotations[i]
		wall.scale = wall_scales[i]
		
		# Create a label for the wall
		var label: Label = Label.new()
		label.text = active_borders[i].name
		label.add_to_group("Labels")
		add_child(label)

		# Position the label near the wall
		label.position = wall_positions[i] + Vector2(10, 10) # Adjust this offset as needed
		label.scale = Vector2(2, 2) # Makes the label larger and easier to see
		
		i += 1
		
func _on_border_coords_moved() -> void:
	wall_positions = [
		Vector2(0, world_size),
		Vector2(0, -world_size),
		Vector2(world_size, 0),
		Vector2(-world_size, 0)
	]
	wall_scales = [
		Vector2(((world_size+23.5)/233*2), 1),
		Vector2(((world_size+23.5)/233*2), 1),
		Vector2(((world_size-23.5)/233*2), 1),
		Vector2(((world_size-23.5)/233*2), 1),
	]
	
	for i:int in range(active_borders.size()):
		var wall: StaticBody2D  = active_borders[i]
		if is_instance_valid(wall):
			wall.position = wall_positions[i]
			wall.scale = wall_scales[i]

func _on_collision_changed(toggle_status: bool) -> void:
	for wall:StaticBody2D in active_borders:
		if is_instance_valid(wall):
			wall.get_node("WorldBoundary").disabled = toggle_status


func toggle_world_borders(active:bool) -> void:
	await get_tree().create_timer(3.0).timeout # Timeout after warp in
	#TODO Remove debug labels
	for label:Label in get_tree().get_nodes_in_group("Labels"):
		label.visible = true if active else false
	# Update border visibility
	for border:StaticBody2D in active_borders:
		border.get_node("WorldBoundary").disabled = false if active else true
		if !active:
			create_tween().tween_property(border, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
		else:
			create_tween().tween_property(border, "modulate", Color(1, 1, 1, 1), Utility.fadeLength)
