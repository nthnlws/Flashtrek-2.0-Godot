extends Resource
class_name ContainerData

@export var contents_name:String
@export var is_mission_goal:bool = true
@export var faction:Utility.FACTION = Utility.FACTION.NEUTRAL
@export var position: Vector2 = Vector2.ZERO

static func create_container_data(contents:String, faction: Utility.FACTION) -> ContainerData:
	var new_container:ContainerData = ContainerData.new()
	new_container.contents_name = contents
	new_container.faction = faction
	new_container.position = Vector2(randi_range(-20000, 20000), (randi_range(-20000, 20000)))
	
	return new_container
