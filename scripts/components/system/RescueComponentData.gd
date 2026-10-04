class_name RescueComponentData
extends SystemComponentData

@export var disabled_ship: ShipState
@export var attacker_faction: Utility.FACTION
@export var difficulty: float = 1.0
@export var max_waves: int = 3
@export var wave_size: int = 2
@export var waves_spawned: int = 0
@export var time_to_next_wave: float = 8.0

const WAVE_INTERVAL: float = 30.0


func _init() -> void:
	component_id = &"rescue"
