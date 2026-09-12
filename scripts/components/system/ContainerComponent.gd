class_name ContainerComponent
extends BaseComponent

var component_data: ContainerComponentData
const PICKUP_SCENE = preload("uid://dess4qrmx6vve")
var active_containers: Array[ContainerPickup]

func initialize(data: BaseComponentData) -> void:
	# Cast the generic data to ContainerComponentData
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
	print("Containers remaining for pickup in component data: %s" % active_containers.size())
	
	if active_containers.is_empty():
		print("Active containers array in component data empty, marking mission as complete")
		mark_completed()


func mark_completed() -> void:
	component_data.is_finished = true
	MissionManager.complete_mission()
