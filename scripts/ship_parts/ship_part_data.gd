extends Resource
class_name ShipPartData
## Single source of truth for a weapon or ability: shop/UI data and gameplay stats.
## Mounted parts read their stats from here (part.data); modifiers are copied
## into the part's tradeoffs on mount.
##
## Purchasable secondary parts: res://assets/data/Secondary Slot Data/
## Ship-bound primary weapons:  res://assets/data/Primary Slot Data/

enum PART_TYPE { WEAPON, ABILITY }

@export_group("Identity")
## Stable key used by saves / inventory. Never change once shipped.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Image shown in the starbase UI.
@export var icon: Texture2D
@export var type: PART_TYPE = PART_TYPE.WEAPON
## Scene instantiated on mount (root must be a Weapon or Ability matching `type`).
@export var scene: PackedScene

@export_group("Unlock")
## Reputation cost, taken from `faction`'s reputation.
@export var unlock_cost: int = 0
## Faction whose reputation pays for the unlock (whose tech it is).
@export var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
## Ship archetypes that cannot mount this part.
@export var disallowed_archetypes: Array[Scaling.ARCHETYPE] = []

@export_group("Stats")
## Base damage before ship/upgrade multipliers (0 = deals no damage).
@export var damage: float = 0.0
## Seconds between uses (weapons and abilities alike).
@export var cooldown: float = 1.0
@export var energy_cost: float = 0.0
## Tradeoffs applied while mounted in the secondary slot. Keys: ShipPartTradeoffs.*
## Parsed by the shop UI; copied into the part's `tradeoffs` on mount.
@export var modifiers: Dictionary = {}


func is_allowed_for(archetype: Scaling.ARCHETYPE) -> bool:
	return not disallowed_archetypes.has(archetype)


## Creates the live part, gives it this data and a copy of the modifiers.
## Returns null (with an error) if the scene is missing or doesn't match `type`.
func instantiate_part() -> Node2D:
	if scene == null:
		push_error("ShipPartData '%s' has no scene" % id)
		return null
	var part: Node2D = scene.instantiate()
	var matches: bool = (part is Weapon) if type == PART_TYPE.WEAPON else (part is Ability)
	if not matches:
		push_error("ShipPartData '%s': scene root does not match type %s" % [id, PART_TYPE.keys()[type]])
		part.free()
		return null
	part.data = self
	part.tradeoffs = modifiers.duplicate()
	return part
