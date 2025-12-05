extends Resource
class_name NeutralData

const BASE_HP:float = 100.0
const BASE_SP:float = 50.0

@export var ship_index:int
@export var world_position: Vector2 = Vector2.ZERO
@export var shield_state: bool = true
@export var movement_target: String
@export var HP_max: float = 100.0
@export var SP_max: float = 50.0
@export var current_hp: float
@export var current_sp: float
@export var ship_type: Utility.SHIP_TYPES = Utility.SHIP_TYPES.Merchantman
@export var is_destroyed: bool = false
@export var difficulty_multiplier: float = 1.0


func check_alive() -> bool:
	return is_destroyed


static func generate_neutral_ship_data(host_planet:PlanetData, faction:Utility.FACTION, difficulty:float, index:int) -> NeutralData:
	var new_neutral_data = NeutralData.new()
	
	new_neutral_data.ship_index = index
	new_neutral_data.world_position = _generate_spawn_position(host_planet)
	new_neutral_data.HP_max = BASE_HP * difficulty
	new_neutral_data.current_hp = new_neutral_data.HP_max
	new_neutral_data.SP_max = BASE_SP * difficulty
	new_neutral_data.current_sp = new_neutral_data.SP_max
	new_neutral_data.ship_type = _get_random_neutral_ship_type()
	new_neutral_data.difficulty_multiplier = difficulty
	
	
	return new_neutral_data


static func _generate_spawn_position(host_planet:PlanetData) -> Vector2:
	# Set spawn distance between 20-80% from starbase to planet
	var random_fraction: float = clamp(randf(), 0.20, 0.80)
	var spawn_pos: Vector2 = Vector2.ZERO.lerp(host_planet.world_position, random_fraction)
	
	return spawn_pos


static func _get_random_neutral_ship_type() -> Utility.SHIP_TYPES:
	var neutral_ship_array:Array[Utility.SHIP_TYPES] = [
		Utility.SHIP_TYPES.Merchantman,
		Utility.SHIP_TYPES.DKora_Marauder,
		Utility.SHIP_TYPES.Hideki_Class,
		Utility.SHIP_TYPES.Tellarite_Cruiser,
		Utility.SHIP_TYPES.Talarian_Freighter,
	]
	return neutral_ship_array.pick_random()
