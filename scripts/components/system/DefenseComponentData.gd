## Succeeds after total_waves; fails when starbase_hp drops to fail_fraction.
class_name DefenseComponentData
extends SystemComponentData

@export var attacker_faction: Utility.FACTION
@export var defended_faction: Utility.FACTION
@export var difficulty: float = 1.0
@export var total_waves: int = 3
@export var waves_cleared: int = 0
@export var base_wave_size: int = 2
@export var starbase_max_hp: float = 1500.0
@export var starbase_hp: float = 1500.0
@export var fail_fraction: float = 0.3


func _init() -> void:
	component_id = &"defense"


func get_wave_size() -> int:
	return base_wave_size + waves_cleared
