extends Node2D
class_name Weapon
## Base for every weapon that can be mounted in PrimarySlot or SecondarySlot.weapon_slot.
## Stats (damage, cooldown, energy cost, modifiers) come from `data` (ShipPartData),
## assigned by ShipPartData.instantiate_part(). The scene only holds behavior tuning.
## The weapon node sits on FiringPosition; projectiles are spawned at the level root
## through slot.spawn_projectile() so they don't move with the ship.
##
## Subclasses override use(pressed) to decide what a press/release means
## (hold-to-fire, single shot, toggle...).

## Stats source. Set before the weapon enters the tree.
var data: ShipPartData = null
## Copy of data.modifiers. Only read when mounted in the secondary slot. Keys: ShipPartTradeoffs.*
var tradeoffs: Dictionary = {}

## Slot this weapon is mounted in (set by the slot on mount).
var slot: ShipSlot = null
## Set by PrimarySlot from the secondary part's FIRE_RATE_MULT tradeoff (2.0 = twice as fast).
var fire_rate_mult: float = 1.0

var _cooldown_left: float = 0.0


## Called by the slot right after the weapon is added to the tree.
func on_mounted(owning_slot: ShipSlot) -> void:
	slot = owning_slot
	if data == null:
		push_error("%s mounted without ShipPartData; mount it via ShipPartData.instantiate_part()" % name)


## Called by the slot right before the weapon is freed.
func on_unmounted() -> void:
	slot = null


## Input entry point: pressed = true on button down, false on button up.
func use(_pressed: bool) -> void:
	pass


func is_ready() -> bool:
	return _cooldown_left <= 0.0


## Seconds between shots after the fire-rate tradeoff.
func get_cooldown() -> float:
	if data == null or fire_rate_mult <= 0.0:
		return 0.0
	return data.cooldown / fire_rate_mult


func start_cooldown() -> void:
	_cooldown_left = get_cooldown()


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_weapon_tick(delta)


## Per-frame hook for subclasses (use instead of overriding _physics_process).
func _weapon_tick(_delta: float) -> void:
	pass
