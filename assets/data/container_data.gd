extends Resource
class_name ContainerData

@export var contents_name:String
@export var is_mission_goal:bool = true
@export var faction:Utility.FACTION = Utility.FACTION.NEUTRAL
@export var spawn_position: Vector2 = Vector2.ZERO
@export var uniqueID: String


## Static function, String contents, Faction, UUID String
static func create_container_data(
		contents:String, new_faction: Utility.FACTION,
		unique_ID: String, spawn_position: Vector2 = Vector2.ZERO) -> ContainerData:
	
	var new_container:ContainerData = ContainerData.new()
	new_container.uniqueID = unique_ID
	new_container.contents_name = contents
	new_container.faction = new_faction
	
	# Generate spawn position if one was not provided
	if spawn_position == Vector2.ZERO:
		new_container.spawn_position = Utility.get_random_point_on_circle(randf_range(5500, 17500))
	else:
		new_container.spawn_position = spawn_position
	
	return new_container
