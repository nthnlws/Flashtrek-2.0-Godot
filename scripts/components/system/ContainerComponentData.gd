extends SystemComponentData
class_name ContainerComponentData


@export var remaining_pickups: Array[ContainerData]


func _init() -> void:
	# Set the specific ID so the Manager knows to spawn the ContainerComponent Node
	component_id = &"container"
