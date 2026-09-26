class_name BaseShipInfo
extends Resource

# Ship info and modifiers
@export var ship_type: Utility.SHIP_TYPES
@export var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
@export var archetype: Scaling.ARCHETYPE = Scaling.ARCHETYPE.NONE
@export var trait_type: Scaling.SHIP_TRAIT = Scaling.SHIP_TRAIT.NONE

# Sprite and collison info
@export var sprite_coords: Vector2
@export var collision_polygon: String
@export var shield_scale: Vector2
@export var muzzle_pos: int

# Base un-scaled amounts
@export var damage_mult: float = 1.0
@export var base_HP: float = 100.0
@export var base_shield: float = 50.0
@export var base_speed: float = 750.0
@export var base_agility: float = 150.0
@export var warp_range: int = 3
@export var base_energy: float = 100.0
@export var base_acceleration: float = 500.0


func _to_string() -> String:
	return """BaseShipInfo {
  ship_name:   %s
  faction:     %s
  archetype:   %s
  trait:       %s
  base_HP:      %d
  base_shield:  %d
  base_speed:       %.1f
  base_agility:     %.1f
  base_energy:  %d
  damage_mult: %.2f
  warp_range:  %d
}""" % [
		Utility.FACTION.keys()[faction],
		Scaling.ARCHETYPE.keys()[archetype],
		Scaling.SHIP_TRAIT.keys()[trait_type],
		base_HP,
		base_shield,
		base_speed,
		base_agility,
		base_energy,
		damage_mult,
		warp_range,
	]
