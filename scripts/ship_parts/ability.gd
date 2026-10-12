extends Node2D
class_name Ability
## Base for every ability that can be mounted in SecondarySlot.ability_slot.
## Intentionally not sharing a parent class with Weapon; SecondarySlot treats
## both through the same members (data, tradeoffs, on_mounted, on_unmounted, use).

## Stats source (cooldown, energy cost, damage...). Set by ShipPartData.instantiate_part().
var data: ShipPartData = null
## Copy of data.modifiers. Keys: ShipPartTradeoffs.*
var tradeoffs: Dictionary = {}

var slot: ShipSlot = null


func on_mounted(owning_slot: ShipSlot) -> void:
	slot = owning_slot


func on_unmounted() -> void:
	slot = null


## Input entry point: pressed = true on button down, false on button up.
func use(_pressed: bool) -> void:
	pass
