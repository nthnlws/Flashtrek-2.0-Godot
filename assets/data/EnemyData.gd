extends Resource
class_name EnemyData

const BASE_HP:float = 100.0
const BASE_SP:float = 50.0

var world_position: Vector2 = Vector2.ZERO
var shield_state: bool = true
var movement_target: String
var HP_max: float = 100.0
var SP_max: float = 50.0
var current_hp: float
var current_sp: float
var ship_type: Utility.SHIP_TYPES = Utility.SHIP_TYPES.Mars_Synth_Defense_Ship
var is_destroyed: bool = false
var difficulty_multiplier: float = 1.0


func check_alive() -> bool:
	return is_destroyed


static func generate_enemy_ship_data(host_planet:PlanetData, faction:Utility.FACTION, difficulty:float) -> EnemyData:
	var new_enemy_data = EnemyData.new()
	
	new_enemy_data.world_position = _generate_spawn_position(host_planet)
	new_enemy_data.HP_max = BASE_HP * difficulty
	new_enemy_data.current_hp = new_enemy_data.HP_max
	new_enemy_data.SP_max = BASE_SP * difficulty
	new_enemy_data.current_sp = new_enemy_data.SP_max
	new_enemy_data.ship_type = _get_ship_type(faction)
	new_enemy_data.difficulty_multiplier = difficulty
	
	
	return new_enemy_data


static func _generate_spawn_position(host_planet:PlanetData) -> Vector2:
	var max_spawn_distance: int = 1500
	var min_spawn_distance: int = 500
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance
	
	return host_planet.world_position + spawn_position


static func _get_ship_type(faction:Utility.FACTION) -> Utility.SHIP_TYPES:
	match faction as Utility.FACTION:
		Utility.FACTION.FEDERATION:
			return Utility.SHIP_TYPES.Ambassador_Class
		Utility.FACTION.KLINGON:
			return Utility.SHIP_TYPES.Brel_Class
		Utility.FACTION.ROMULAN:
			return Utility.SHIP_TYPES.Dderidex_Class
		Utility.FACTION.NEUTRAL:
			return Utility.SHIP_TYPES.JemHadar
		_:
			push_error("Unknown faction type %s" % faction)
			return Utility.SHIP_TYPES.Merchantman
