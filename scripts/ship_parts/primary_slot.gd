extends ShipSlot
class_name PrimarySlot
## Primary slot: always a Weapon, fired with left click. No tradeoffs of its own;
## listens to SecondarySlot.tradeoffs_changed for FIRE_RATE_MULT.

## Ship's static primary weapon (purchased weapons only go in the secondary slot).
@export var default_weapon: ShipPartData

var weapon: Weapon = null
var fire_rate_mult: float = 1.0


func _ready() -> void:
	if default_weapon:
		mount_data(default_weapon)


## Creates the weapon from its data and mounts it.
func mount_data(part_data: ShipPartData) -> void:
	var new_weapon: Node2D = part_data.instantiate_part() if part_data else null
	if new_weapon is Weapon:
		mount(new_weapon)
	elif new_weapon:
		push_error("PrimarySlot: '%s' is not a weapon" % part_data.id)
		new_weapon.free()


## Replaces the current primary weapon.
func mount(new_weapon: Weapon) -> void:
	_detach(weapon)
	weapon = new_weapon
	if weapon:
		_attach(weapon)
		weapon.fire_rate_mult = fire_rate_mult


func _unhandled_input(event: InputEvent) -> void:
	if weapon == null:
		return
	if event.is_action_pressed("left_click"):
		weapon.use(true)
	elif event.is_action_released("left_click"):
		weapon.use(false)


## Connected to SecondarySlot.tradeoffs_changed.
func on_secondary_tradeoffs_changed(tradeoffs: Dictionary) -> void:
	fire_rate_mult = tradeoffs.get(ShipPartTradeoffs.FIRE_RATE_MULT, 1.0)
	if weapon:
		weapon.fire_rate_mult = fire_rate_mult
