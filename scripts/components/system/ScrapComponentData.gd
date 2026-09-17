class_name ScrapComponentData
extends SystemComponentData

@export var scrap_piles: ResourceGroup = load("res://assets/data/all_scrap_piles.tres")
@export var component_scrap_piles: Array[ScrapPileConfig] = []


func _init() -> void:
	component_id = &"scrap"


func setup_data(number_of_piles: int) -> void:
	var all_scrap_list: Array[ScrapPileConfig] = []
	scrap_piles.load_all_into(all_scrap_list)

	for i: int in range(number_of_piles):
		var pile_data: ScrapPileConfig = all_scrap_list.pick_random()
		component_scrap_piles.append(pile_data)
