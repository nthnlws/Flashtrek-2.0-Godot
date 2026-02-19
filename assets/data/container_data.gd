extends Resource
class_name ContainerData

@export var contents_name:String
@export var is_mission_goal:bool = true
@export var faction:Utility.FACTION = Utility.FACTION.NEUTRAL
@export var spawn_position: Vector2 = Vector2.ZERO

static func create_container_data(contents:String, new_faction: Utility.FACTION) -> ContainerData:
	var new_container:ContainerData = ContainerData.new()
	new_container.contents_name = contents
	new_container.faction = new_faction
	var random_spawn_point:Vector2 = Utility.get_random_point_on_circle(randf_range(5500, 17500))
	new_container.spawn_position = random_spawn_point
	
	return new_container
