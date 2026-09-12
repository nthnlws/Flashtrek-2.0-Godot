extends BaseComponentData
class_name ContainerComponentData


@export var remaining_pickups: Array[ContainerData]


func _init() -> void:
	# Set the specific ID so the Manager knows to spawn the ContainerComponent Node
	component_id = &"container"


#TODO: Make faction input variable array to allow for containers of
# multiple factions to spawn in same component
func setup_data(cargo_name: String, faction: Utility.FACTION, spawn_positions: Array[Vector2]) -> void:
	var num_containers: int = spawn_positions.size()
	
	for pos: Vector2 in spawn_positions:
		var new_data: ContainerData = ContainerData.create_container_data(cargo_name, faction, UUID.generate_UUID(), pos)
		remaining_pickups.append(new_data)
