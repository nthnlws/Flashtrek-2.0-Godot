class_name ContainerComponent
extends SystemComponent

var system_containers: Array[ContainerData]
var remaining_containers: Array[ContainerPickup]
const CONTAINER = preload("uid://dess4qrmx6vve")


func _on_ready_logic() -> void:
	create_container_data() # Add new data to SystemData
	system_containers = system_data.get_containers() # Get containers added
	spawn_containers() # Spawn based on ContainerData in SystemData


func create_container_data() -> void:
	var new_data: ContainerData = ContainerData.create_container_data(mission_data.cargo, mission_data.faction_owner)
	system_data.add_container(new_data)


func spawn_containers() -> void:
	var spawn_folder: Node = get_tree().get_root().get_node("Game/Level/item_pickups")
	for data:ContainerData in system_containers:
		var new_container:ContainerPickup = CONTAINER.instantiate()
		new_container.container_data = data
		new_container.global_position = data.position
		spawn_folder.add_child(new_container)
