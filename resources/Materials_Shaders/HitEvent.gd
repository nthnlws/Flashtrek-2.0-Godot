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
var hit_position:Vector2

var target_name:String
var target_class:String

var is_critical_hit:bool
var is_continuous_damage:bool
var damage_amount:float


func get_shooter_node() -> Node:
	if shooter_instance_id != 0:
		var node = instance_from_id(shooter_instance_id)
		if is_instance_valid(node):
			return node
	printerr("No node found for provided ID in HitEvent")
	return null
