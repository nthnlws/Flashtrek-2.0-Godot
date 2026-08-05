extends Resource
class_name HitEvent

enum SHOOTER_TYPE { PLAYER, FACTION, NEUTRAL, PLANET, BOSS, UNKNOWN }
enum WEAPON_TYPE { TORPEDO, MISSILE }

# Created with shooter.get_instance_id()
var shooter_instance_id:int 
var shooter_faction:Utility.FACTION
#var shooter_type:SHOOTER_TYPE

#var weapon_type:WEAPON_TYPE
#var firing_pos:Vector2
var projectile_ID:String
var hit_position:Vector2 = Vector2(0.0, 0.0)
var hit_hull:bool = false
var hit_shield:bool = false

var damage_source: SOURCE
var is_from_player: bool = false
var is_critical_hit: bool = false
var is_continuous_damage: bool
var damage_amount: float = 0.0

enum SOURCE { PLAYER, KLINGON, ROMULAN, FEDERATION, NEUTRAL }

func get_shooter_node() -> Node:
	if shooter_instance_id != 0:
		var node = instance_from_id(shooter_instance_id)
		if is_instance_valid(node):
			return node
	printerr("No node found for provided ID in HitEvent")
	return null
