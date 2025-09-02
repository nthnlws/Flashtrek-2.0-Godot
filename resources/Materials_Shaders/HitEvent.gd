extends Resource
class_name HitEvent

enum SHOOTER_TYPE {PLAYER, FACTION, NEUTRAL, PLANET, BOSS, UNKNOWN}
enum WEAPON_TYPE {TORPEDO, MISSILE}

# Created with shooter.get_instance_id()
# var shooter_node = instance_from_id(hit_event.shooter_instance_id)
# if is_instance_valid(shooter_node):
var shooter_instance_id:int 
var shooter_faction:Utility.FACTION
var shooter_type:SHOOTER_TYPE

var weapon_type:WEAPON_TYPE
var firing_pos:Vector2
var hit_pos:Vector2

var target_name:String
var target_class:String

var is_critical_hit:bool
var damage:float
