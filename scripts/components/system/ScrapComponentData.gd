class_name ScrapComponentData
extends SystemComponentData

@export var scrap_piles: ResourceGroup = load("res://assets/data/all_scrap_piles.tres")
@export var component_scrap_piles: Array[ScrapPileConfig] = []


func _init() -> void:
	component_id = &"scrap"


## Ignores `mission` - Scrap components don't read anything from a mission
func setup_from_mission(mission: MissionData, context: SystemData) -> void:
	var all_scrap_list: Array[ScrapPileConfig] = []
	scrap_piles.load_all_into(all_scrap_list)

	var number_of_piles: int = randi_range(3, 6)
	for i: int in range(number_of_piles):
		var pile_data: ScrapPileConfig = all_scrap_list.pick_random()
		component_scrap_piles.append(pile_data)
