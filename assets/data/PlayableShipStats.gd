extends Resource
class_name PlayableShipStats

@export var faction: Utility.FACTION
@export var ship_name: String
@export var archetype: Scaling.ARCHETYPE
@export var trait_type: Scaling.SHIP_TRAIT
@export var damage_mult: float
@export var max_hp: float
@export var max_shield: float
@export var speed: float
@export var agility: float
@export var warp_range: int
@export var stat_ranges: Dictionary[Utility.FACTION, Dictionary]
@export var max_energy: int


func _to_string() -> String:
	return """PlayableShipStats {
  ship_name:   %s
  faction:     %s
  archetype:   %s
  trait:       %s
  max_hp:      %d
  max_shield:  %d
  speed:       %.1f
  agility:     %.1f
  max_energy:  %d
  damage_mult: %.2f
  warp_range:  %d
  stat_ranges:  [%s]
}""" % [
		ship_name,
		Utility.FACTION.keys()[faction],
		Scaling.ARCHETYPE.keys()[archetype],
		Scaling.SHIP_TRAIT.keys()[trait_type],
		max_hp,
		max_shield,
		speed,
		agility,
		max_energy,
		damage_mult,
		warp_range,
		", ".join(stat_ranges.get(faction).values())#.map(func(f): return Utility.FACTION.keys()[f]))
	]
