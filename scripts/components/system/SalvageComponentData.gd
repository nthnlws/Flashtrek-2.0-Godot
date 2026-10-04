## Salvage mission debris field, independent of ScrapComponentData.
## Built by ComponentGenerator.build_salvage().
## Salvage keys are Vector2i(pile_index, piece_index).
class_name SalvageComponentData
extends SystemComponentData

@export var component_scrap_piles: Array[ScrapPileConfig] = []
## Parallel to component_scrap_piles, relative to field_center.
@export var pile_positions: Array[Vector2] = []
@export var field_center: Vector2 = Vector2.ZERO

@export var remaining_salvage: Array[Vector2i] = []
@export var collected_salvage: Array[Vector2i] = []
@export var total_salvage: int = 0


func _init() -> void:
	component_id = &"salvage"


## Backfills positions missing from older saves.
func get_pile_position(index: int) -> Vector2:
	while pile_positions.size() <= index:
		pile_positions.append(Utility.get_random_point_on_circle(randf_range(0.0, ComponentGenerator.SCRAP_FIELD_RADIUS)))
	return pile_positions[index]
