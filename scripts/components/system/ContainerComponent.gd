class_name ContainerComponent
extends SystemComponent

var component_data: ContainerComponentData
const PICKUP_SCENE = preload("uid://dess4qrmx6vve")
var active_containers: Array[ContainerPickup]

func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as ContainerComponentData

	# Spawn containers in-level
	for container_data: ContainerData in component_data.remaining_pickups:
		var pickup: ContainerPickup = PICKUP_SCENE.instantiate()

		pickup.global_position = container_data.spawn_position
		pickup.container_data = container_data

		# Signal connection
		pickup.container_collected.connect(_on_container_picked_up)

		add_child(pickup)
		LevelManager.containers.append(pickup)
		active_containers.append(pickup)


func _on_container_picked_up(container: ContainerPickup) -> void:
	# Removes this position from array
	active_containers.erase(container)
	LevelManager.containers.erase(container)
	print("Containers remaining for pickup in component data: %s" % active_containers.size())

	if active_containers.is_empty():
		print("Active containers array in component data empty, marking mission as complete")
		MissionManager.complete_mission()
		complete(component_data)
