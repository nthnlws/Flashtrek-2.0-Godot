extends Resource
class_name HitEvent

enum TYPES {PLAYER, FACTION, NEUTRAL, PLANET, BOSS, UNKNOWN}

var shooter_object:Node
var shooter_faction:Utility.FACTION
var shooter_type:TYPES
var firing_pos:Vector2
var hit_pos:Vector2

var target_name:String
var target_class:String
var damage:float
