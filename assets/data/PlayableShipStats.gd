extends Resource
class_name PlayableShipStats

@export var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
@export var ship_name: String = "PlayerShip"
@export var archetype: Scaling.ARCHETYPE = Scaling.ARCHETYPE.NONE
@export var trait_type: Scaling.SHIP_TRAIT = Scaling.SHIP_TRAIT.NONE
@export var damage_mult: float = 1.0
@export var max_hp: float = 100.0
@export var max_shield: float = 50.0
@export var speed: float = 750.0
@export var agility: float = 150.0
@export var warp_range: int = 3
@export var stat_ranges: Dictionary[Utility.FACTION, Dictionary]
@export var max_energy: float = 100.0


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
