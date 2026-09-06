extends Resource
class_name ShipState

enum CATEGORY { FACTION, NEUTRAL, MISSION, PLAYER }
@export var ship_category: CATEGORY

# Ship info and capabilities
@export var ship_type: Utility.SHIP_TYPES
@export var current_faction: Utility.FACTION
@export var ship_name: String = "NewShip"
@export var unlock_cost: int
@export var cargo_capacity: int
@export var reputation_value: int
@export var is_mission_goal: bool = false

# Scaled stats
@export var scaled_max_HP: float
@export var scaled_max_shield: float
@export var scaled_speed: float
@export var scaled_agility: float
@export var scaled_damage_mult: float
@export var scaled_warp_range: int
@export var scaled_energy: float
@export var scaled_acceleration: float

# Ship state variables
@export var unique_id: String
@export var save_position: Vector2
@export var save_health: float
@export var save_shield_health: float
@export var save_shield_status: bool

# Divisor to multiply speed against for NPC ships
const NPC_SPEED_DIVISOR: int = 6


func save_ship_state(position:Vector2, health:float, shield_health:float, shield_status:bool = true):
	save_position = position
	save_health = health
	save_shield_health = shield_health
	save_shield_status = shield_status


## Returns player-based scaled resource
static func get_player_scaled_stats(unlock_index: int, total_unlocks: int, base_ship: BaseShipInfo) -> ShipState:
	var new_state: ShipState = ShipState.new()
	var t: float = Scaling.get_norm_t(unlock_index, total_unlocks)
	
	var stat_scale: float = Scaling.get_player_stat_scale(t)
	var move_scale: float = Scaling.get_player_move_scale(t)
	var energy_scale: float = Scaling.get_player_energy_scale(t)
	
	new_state.unique_id = UUID.generate_UUID()
	new_state.ship_category = CATEGORY.PLAYER
	new_state.ship_type = base_ship.ship_type
	new_state.current_faction = base_ship.faction
	
	new_state.unlock_cost = Scaling.get_unlock_cost_scale(float(unlock_index) / float(total_unlocks))
	
	new_state.scaled_max_HP = Scaling.apply_modifiers(base_ship.base_HP, stat_scale, base_ship.archetype, base_ship.faction, "MAX_HP")
	new_state.scaled_max_shield = Scaling.apply_modifiers(base_ship.base_shield, stat_scale, base_ship.archetype, base_ship.faction, "MAX_SHIELD")
	new_state.scaled_speed = Scaling.apply_modifiers(base_ship.base_speed, move_scale, base_ship.archetype, base_ship.faction, "SPEED")
	new_state.scaled_agility = Scaling.apply_modifiers(base_ship.base_agility, move_scale, base_ship.archetype, base_ship.faction, "AGILITY")
	new_state.scaled_damage_mult = Scaling.apply_modifiers(base_ship.damage_mult, stat_scale, base_ship.archetype, base_ship.faction, "DAMAGE")
	new_state.scaled_warp_range = Scaling.get_ship_warp_range(unlock_index)
	new_state.scaled_energy = snappedi(150.0 * energy_scale, 25)
	new_state.scaled_acceleration = base_ship.base_acceleration

	return new_state


## Returns NPC-based scaled resource
static func get_NPC_scaled_stats(system_difficulty: float, base_ship: BaseShipInfo, category: CATEGORY) -> ShipState:
	var new_state: ShipState = ShipState.new()
	
	new_state.unique_id = UUID.generate_UUID()
	new_state.ship_category = category
	new_state.ship_type = base_ship.ship_type
	new_state.reputation_value = 100 * system_difficulty
	
	new_state.scaled_max_HP = base_ship.base_HP * system_difficulty
	new_state.save_health = base_ship.base_HP * system_difficulty
	new_state.scaled_max_shield = base_ship.base_shield * system_difficulty
	new_state.save_shield_health = base_ship.base_shield * system_difficulty
	
	new_state.scaled_acceleration = base_ship.base_acceleration
	new_state.scaled_speed = base_ship.base_speed / NPC_SPEED_DIVISOR
	new_state.scaled_agility = base_ship.base_agility
	new_state.scaled_damage_mult = base_ship.damage_mult * system_difficulty
	new_state.scaled_energy = base_ship.base_energy * system_difficulty

	return new_state
