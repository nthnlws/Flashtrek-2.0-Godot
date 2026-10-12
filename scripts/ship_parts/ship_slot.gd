extends Node
class_name ShipSlot
## Shared plumbing for PrimarySlot and SecondarySlot: links to the ship's systems
## and helpers that mounted weapons/abilities call (energy, damage, projectiles).
## Mounted parts become children of firing_position.

@export_category("Linked Nodes")
@export var ship: CharacterBody2D
@export var energy_component: EnergyComponent
@export var shield: Shield
@export var hitbox: HullDamageReceiver
@export var firing_position: Marker2D

## Set by the ship in sync_ship_to_data.
var upgrades: ShipStatModifiers = ShipStatModifiers.new()
var ship_damage_multiplier: float = 1.0


## Shared "can the ship use weapons/abilities right now" check (lives on the ship).
func can_use() -> bool:
	if is_instance_valid(ship) and ship.has_method("can_use"):
		return ship.can_use()
	return Utility.current_gamestate == Utility.GAMESTATE.SYSTEM


## Standard damage multiplier (see Scaling.get_damage_mult).
func get_damage_mult() -> float:
	return Scaling.get_damage_mult(ship_damage_multiplier, upgrades)


func get_faction() -> Utility.FACTION:
	return ship.ship_stats.current_faction


## Spends energy if available. Returns false (and spends nothing) if not enough.
func spend_energy(cost: float, regen_lock_seconds: float) -> bool:
	if not is_instance_valid(energy_component):
		return true
	if not energy_component.request_consume(cost):
		return false
	energy_component.consume_energy(cost)
	energy_component.lock_regeneration(regen_lock_seconds)
	return true


## Fills in shooter, faction and self-hit exceptions on a projectile
## (Torpedo / HomingMissile share these fields).
func prepare_projectile(projectile: Node) -> void:
	projectile.shooterObject = ship
	projectile.faction = get_faction()
	if is_instance_valid(hitbox):
		projectile.exceptions.append(hitbox)
	if is_instance_valid(shield):
		projectile.exceptions.append(shield.get_node("shield_area"))


## Adds a projectile at the level root so it doesn't inherit the ship's movement.
func spawn_projectile(projectile: Node) -> void:
	var root: Node = LevelManager.rootLevel if is_instance_valid(LevelManager.rootLevel) else get_tree().current_scene
	root.add_child(projectile)


func _attach(part: Node2D) -> void:
	firing_position.add_child(part)
	part.on_mounted(self)


func _detach(part: Node2D) -> void:
	if part == null:
		return
	part.on_unmounted()
	part.get_parent().remove_child(part)
	part.queue_free()
