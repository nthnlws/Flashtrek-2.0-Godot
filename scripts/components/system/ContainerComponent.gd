class_name ContainerComponent
extends BaseComponent

var component_data: ContainerComponentData
const PICKUP_SCENE = preload("uid://dess4qrmx6vve")

func initialize(data: BaseComponentData) -> void:
	# Cast the generic data to our specific type
	component_data = data as ContainerComponentData
	
	# Spawn containers based on the data
	for pos in component_data.uncollected_positions:
		var pickup: ContainerPickup = PICKUP_SCENE.instantiate()
		
		# Set physical position and remember it for data-syncing
		pickup.global_position = pos
		pickup.original_position = pos 
		
		# Connect the physical pickup event to our sync function
		pickup.collected.connect(_on_pickup_collected)
		
		add_child(pickup)


# When the node is collected, update the Data
func _on_pickup_collected(pos: Vector2) -> void:
	component_data.collect_container(pos)
