extends ShipSlot
class_name SecondarySlot
## Secondary slot: holds either a Weapon or an Ability (or nothing), used with right click.
## Two typed vars, at most one is set. Only mount_weapon / mount_ability / unmount
## should write them, so mounting one type always replaces the other.

## Emitted after every mount/unmount with the mounted part's tradeoffs ({} when blank).
## Listeners update cached values (max energy, max hull/shield, primary fire rate).
signal tradeoffs_changed(tradeoffs: Dictionary)

## Weapon or Ability mounted on spawn. Leave empty for a blank slot.
@export var default_part: ShipPartData

var weapon_slot: Weapon = null
var ability_slot: Ability = null

## Tradeoffs of whatever is mounted. Read on demand, e.g.
## secondary_slot.tradeoffs.get(ShipPartTradeoffs.AGILITY_MULT, 1.0)
var tradeoffs: Dictionary:
	get:
		var part: Node2D = get_mounted()
		return part.tradeoffs if part else {}


func _ready() -> void:
	if default_part:
		mount_data(default_part)


## Creates the part from its data and mounts it in the matching sub-slot.
## Archetype restrictions (part_data.is_allowed_for) are enforced by the swap UI, not here.
func mount_data(part_data: ShipPartData) -> void:
	var part: Node2D = part_data.instantiate_part() if part_data else null
	if part:
		mount_part(part)


## Mounts any Weapon or Ability instance into the right sub-slot.
func mount_part(part: Node2D) -> void:
	if part is Weapon:
		mount_weapon(part)
	elif part is Ability:
		mount_ability(part)
	else:
		push_error("SecondarySlot: %s is neither a Weapon nor an Ability" % part)
		part.queue_free()


func mount_weapon(new_weapon: Weapon) -> void:
	_clear()
	weapon_slot = new_weapon
	_attach(weapon_slot)
	refresh_tradeoffs()


func mount_ability(new_ability: Ability) -> void:
	_clear()
	ability_slot = new_ability
	_attach(ability_slot)
	refresh_tradeoffs()


## Leaves the slot blank.
func unmount() -> void:
	_clear()
	refresh_tradeoffs()


## The mounted part (Weapon or Ability), or null when blank.
func get_mounted() -> Node2D:
	if weapon_slot:
		return weapon_slot
	return ability_slot


## Re-emits tradeoffs_changed so listeners resync (also used once by the ship after wiring).
func refresh_tradeoffs() -> void:
	tradeoffs_changed.emit(tradeoffs)


func _clear() -> void:
	_detach(weapon_slot)
	_detach(ability_slot)
	weapon_slot = null
	ability_slot = null


func _unhandled_input(event: InputEvent) -> void:
	var part: Node2D = get_mounted()
	if part == null:
		return
	if event.is_action_pressed("right_click"):
		part.use(true)
	elif event.is_action_released("right_click"):
		part.use(false)
