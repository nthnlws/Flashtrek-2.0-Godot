extends NeutralShipData
class_name MissionShipData

var is_hostile: bool = false

static func generate_mission_ship_data(spawn_position:Vector2, faction:Utility.FACTION, difficulty:float, index:int, ship_type_param:Utility.SHIP_TYPES = Utility.SHIP_TYPES.Merchantman, is_hostile_param:bool = false) -> MissionShipData:
	var new_ship_data = MissionShipData.new()
	
	new_ship_data.ship_index = index
	new_ship_data.world_position = spawn_position
	new_ship_data.HP_max = BASE_HP * difficulty
	new_ship_data.current_hp = new_ship_data.HP_max
	new_ship_data.SP_max = BASE_SP * difficulty
	new_ship_data.current_sp = new_ship_data.SP_max
	new_ship_data.ship_type = ship_type_param
	new_ship_data.difficulty_multiplier = difficulty
	new_ship_data.is_hostile = is_hostile_param
	
	
	return new_ship_data
