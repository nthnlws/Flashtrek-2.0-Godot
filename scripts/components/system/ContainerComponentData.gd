extends SystemComponentData
class_name ContainerComponentData


@export var remaining_pickups: Array[ContainerData]


func _init() -> void:
	# Set the specific ID so the Manager knows to spawn the ContainerComponent Node
	component_id = &"container"


#TODO: Make faction input variable array to allow for containers of
# multiple factions to spawn in same component
## Called by SystemData.add_component() when the mission is created.
func setup_from_mission(mission: MissionData, context: SystemData) -> void:
	var spawn_positions: Array[Vector2] = []
	for i in range(randi_range(2, 4)): # Number of containers to spawn
		spawn_positions.append(Utility.get_random_point_on_circle(randf_range(2000, 6000)))

	for pos: Vector2 in spawn_positions:
		var new_data: ContainerData = ContainerData.create_container_data(mission.cargo, mission.faction_owner, UUID.generate_UUID(), pos)
		remaining_pickups.append(new_data)
