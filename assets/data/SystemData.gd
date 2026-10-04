# SystemData.gd
extends Resource
class_name SystemData

var planet_names: Array[String]
const planet_name_file: String = "res://assets/data/planet_names.txt"

# System info
@export var system_name: String
@export var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
@export var system_index: int = 0
@export var system_size: int = 20000
@export var components: Array[BaseComponentData] = []

## Builds the system-scoped component registered as `component_id` via
## ComponentGenerator and stores it on this system. `mission` may be null for
## components that don't need one.
func add_component(component_id: StringName, mission: MissionData) -> SystemComponentData:
	var definition: ComponentDefinition = ComponentRegistry.get_definition(component_id)
	if definition == null or definition.scope != ComponentDefinition.Scope.SYSTEM:
		printerr("SystemData: no system-scoped component registered for id '%s'" % component_id)
		return null

	var data: SystemComponentData = ComponentGenerator.build(component_id, {"mission": mission, "system": self}) as SystemComponentData
	if data == null:
		return null
	components.append(data)
	return data

# System contents
@export var planet_data: Array[PlanetData]
@export var sun_data: SunData
@export var enemy_list: Array[ShipState]
@export var mission_ship_list: Array[ShipState] = []
@export var defeated_enemies: Array[ShipState] = []
@export var neutral_list: Array[ShipState]
@export var defeated_neutrals: Array[ShipState] = []
@export var mission_containers: Array[ContainerData] = []

# System logic
@export var enemies_defeated: bool = false
@export var neutrals_defeated: bool = false
@export var system_difficulty_mult: float = 1.0

# Galaxy map info
@export var global_map_position: Vector2
@export var neighbor_ids: Array[int] = []
var warp_neighbors: Array[SystemData]


func _to_string() -> String:
	return "--- %s system data. %s planets, %s active NPCs, %1.2f difficulty mult ---" % [self.system_name, str(planet_data.size()), str(enemy_list.size() + neutral_list.size()), system_difficulty_mult]


func get_containers() -> Array[ContainerData]:
	return mission_containers

func add_container(container_data:ContainerData) -> void:
	mission_containers.append(container_data)

func remove_container(to_remove: ContainerData) -> void:
	if mission_containers.has(to_remove):
		mission_containers.erase(to_remove)
	else: printerr("ContainerData does not exist in SystemData, cannot remove")


## Loads (and shuffles) the shared planet-name pool the first time this
## SystemData needs a name during procedural generation.
func ensure_planet_names_loaded() -> void:
	if planet_names.is_empty():
		planet_names = Utility.load_text_file(planet_name_file)
		planet_names.shuffle()


func get_planet_data(planet_name: String) -> PlanetData:
	for planet: PlanetData in planet_data:
		if planet.name == planet_name:
			return planet
	
	return null # If PlanetData not found


func remove_faction_ship_data(to_remove: ShipState) -> void:
	var found: ShipState
	for ship: ShipState in enemy_list:
		if ship.unique_id == to_remove.unique_id:
			found = ship
	enemy_list.erase(found)
	defeated_enemies.append(found)


func remove_neutral_ship_data(to_remove: ShipState) -> void:
	var found: ShipState
	for ship: ShipState in neutral_list:
		if ship.unique_id == to_remove.unique_id:
			found = ship
	neutral_list.erase(found)
	defeated_neutrals.append(found)
