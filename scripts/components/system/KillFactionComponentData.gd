class_name KillFactionComponentData
extends SystemComponentData

@export var faction: Utility.FACTION
@export var target_ships_data: Array[ShipState]

func _init() -> void:
	component_id = &"kill_faction"
