extends Weapon
class_name TorpedoLauncher
## Default primary weapon. Hold to fire torpedoes toward the cursor,
## limited to a forward cone.

@export var projectile_scene: PackedScene = preload("uid://dkwrosj64i8ur") # torpedo.tscn
## Max angle (degrees) between ship heading and target.
@export var max_valid_angle: float = 35.0
@export var regen_lock_seconds: float = 0.5

var _held: bool = false


func use(pressed: bool) -> void:
	_held = pressed


func on_unmounted() -> void:
	_held = false
	super()


func _weapon_tick(_delta: float) -> void:
	if _held and data and is_ready() and slot and slot.can_use():
		try_fire(get_global_mouse_position())


## Returns true if a torpedo was fired.
func try_fire(target_position: Vector2) -> bool:
	var origin: Vector2 = global_position
	var firing_angle: float = origin.angle_to_point(target_position)
	if absf(angle_difference(slot.ship.rotation, firing_angle)) > deg_to_rad(max_valid_angle):
		return false
	if not slot.spend_energy(data.energy_cost, regen_lock_seconds):
		return false

	var torpedo: Torpedo = projectile_scene.instantiate()
	torpedo.global_position = origin
	torpedo.rotation = firing_angle
	torpedo.damage = Scaling.get_weapon_damage(data.damage, slot.ship_damage_multiplier, slot.upgrades)
	torpedo.damage_multipler = slot.get_damage_mult()
	slot.prepare_projectile(torpedo)
	slot.spawn_projectile(torpedo)
	start_cooldown()
	return true
