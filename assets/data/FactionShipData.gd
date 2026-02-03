extends NeutralShipData
class_name FactionShipData



static func generate_enemy_ship_data(spawn_position:Vector2, faction:Utility.FACTION, difficulty:float, index:int) -> FactionShipData:
	var new_enemy_data = FactionShipData.new()
	
	new_enemy_data.ship_index = index
	new_enemy_data.world_position = spawn_position
	new_enemy_data.HP_max = BASE_HP * difficulty
	new_enemy_data.current_hp = new_enemy_data.HP_max
	new_enemy_data.SP_max = BASE_SP * difficulty
	new_enemy_data.current_sp = new_enemy_data.SP_max
	new_enemy_data.ship_type = _get_faction_ship_type(faction)
	new_enemy_data.difficulty_multiplier = difficulty
	
	
	return new_enemy_data


static func _get_faction_ship_type(faction:Utility.FACTION) -> Utility.SHIP_TYPES:
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
