extends Node
class_name WeaponsComponent
## NPC-only primary weapon (torpedo). The player uses PrimarySlot / SecondarySlot
## (scripts/ship_parts/) instead. AI calls attempt_primary_fire().

var upgrades: ShipStatModifiers = ShipStatModifiers.new()

@export var apply_randomness: bool = false
@export var accuracy_cone_angle: float = 3.0 # In degrees
@export var base_rate_of_fire: float = 5.0
@export var max_valid_angle: float = 35.0
@export var ship_damage_multiplier: float = 1.0

@export_category("Linked Nodes")
@export var parent_entity: CharacterBody2D
@export var energy_component: EnergyComponent
@export var shield: Shield
@export var hitbox: HullDamageReceiver
@export var firing_position: Marker2D

@export_group("PackedScenes")
@export var torpedo_scene: PackedScene = preload("uid://dkwrosj64i8ur")

@onready var cooldown_timer: Timer = $cooldown_timer

var rate_of_fire: float = 1.0 / base_rate_of_fire:
	set(value):
		cooldown_timer.wait_time = 1.0 / value
		rate_of_fire = value


var _torpedo_cost: float = 0.0


func _ready() -> void:
	cooldown_timer.wait_time = rate_of_fire
	var prototype: Torpedo = torpedo_scene.instantiate()
	_torpedo_cost = prototype.energy_drain
	prototype.free()


## Returns true if fired. Safe to call every frame.
func attempt_primary_fire(target_location: Vector2) -> bool:
	if not cooldown_timer.is_stopped():
		return false

	var firing_angle: float = firing_position.global_position.angle_to_point(target_location)
	var angle_diff: float = angle_difference(parent_entity.rotation, firing_angle)
	# Early exit for invalid shooting angle
	if abs(angle_diff) > deg_to_rad(max_valid_angle): return false
	
	if apply_randomness:
		target_location = randomize_position(target_location)
		# Recalculate firing angle after randomization
		firing_angle = firing_position.global_position.angle_to_point(target_location)
	
	if _can_fire(_torpedo_cost):
		var bullet: Torpedo = torpedo_scene.instantiate()
		cooldown_timer.start()
		bullet.global_position = firing_position.global_position
		bullet.rotation = firing_angle
		bullet.shooterObject = parent_entity
		bullet.damage = Scaling.get_weapon_damage(bullet.damage, ship_damage_multiplier, upgrades)
		bullet.damage_multipler = Scaling.get_damage_mult(ship_damage_multiplier, upgrades)
		bullet.faction = parent_entity.ship_stats.current_faction
		
		if hitbox:
			bullet.exceptions.append(hitbox)
		if shield:
			bullet.exceptions.append(shield.get_node("shield_area"))
		
		if energy_component:
			energy_component.consume_energy(_torpedo_cost)
			energy_component.lock_regeneration(0.5)
		
		add_child(bullet)
		return true
	return false


func randomize_position(predicted_position: Vector2) -> Vector2:
	var distance: float = firing_position.global_position.distance_to(predicted_position)
	var max_radius: float = distance * tan(deg_to_rad(accuracy_cone_angle))
	var random_offset: Vector2 = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * max_radius
	
	return predicted_position + random_offset


func _can_fire(cost: float) -> bool:
	if Utility.current_gamestate != Utility.GAMESTATE.SYSTEM:
		return false
		
	if not cooldown_timer.is_stopped():
		return false
		
	if energy_component:
		return energy_component.request_consume(cost)
		
	return true
